//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AVFoundation
import Combine

import MatrixRustSDK

final class QRCodeLoginService: QRCodeLoginServiceProtocol {
    private let oidcConfiguration: OidcConfiguration
    private let encryptionKeyProvider: EncryptionKeyProviderProtocol
    private let userSessionStore: UserSessionStoreProtocol
    private var client: Client?
    
    private let qrLoginProgressSubject = PassthroughSubject<QrLoginProgress, Never>()
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> {
        qrLoginProgressSubject.eraseToAnyPublisher()
    }
    
    init(oidcConfiguration: OidcConfiguration,
         encryptionKeyProvider: EncryptionKeyProviderProtocol,
         userSessionStore: UserSessionStoreProtocol) {
        self.oidcConfiguration = oidcConfiguration
        self.encryptionKeyProvider = encryptionKeyProvider
        self.userSessionStore = userSessionStore
    }
    
    func scan(data: Data) async throws {
        let qrData = try QrCodeData.fromBytes(bytes: data)
        let listener = QrLoginProgressListenerProxy { [weak self] in self?.qrLoginProgressSubject.send($0) }
    
        client = try await ClientBuilder()
            .basePath(path: userSessionStore.baseDirectory.path(percentEncoded: false))
            .passphrase(passphrase: encryptionKeyProvider.generateKey().base64EncodedString())
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .enableCrossProcessRefreshLock(processId: InfoPlistReader.main.bundleIdentifier,
                                           sessionDelegate: userSessionStore.clientSessionDelegate)
            .serverVersions(versions: ["v1.0", "v1.1", "v1.2", "v1.3", "v1.4", "v1.5"]) // FIXME: Quick and dirty fix for stopping version requests on startup https://github.com/matrix-org/matrix-rust-sdk/pull/1376
            .buildWithQrCode(qrCodeData: qrData, oidcConfiguration: oidcConfiguration, progressListener: listener)
    }
    
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Determine if the user previously authorized camera access.
        if status == .authorized {
            return true
        }
        
        var isAuthorized = false
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        return isAuthorized
    }
}

final class QrLoginProgressListenerProxy: QrLoginProgressListener {
    private let onUpdateClosure: (QrLoginProgress) -> Void
    
    init(onUpdateClosure: @escaping (QrLoginProgress) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(state: QrLoginProgress) {
        onUpdateClosure(state)
    }
}
