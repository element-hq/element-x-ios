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
    private let passphrase: String
    private let userSessionStore: UserSessionStoreProtocol
    
    private let qrLoginProgressSubject = PassthroughSubject<QrLoginProgress, Never>()
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> {
        qrLoginProgressSubject.eraseToAnyPublisher()
    }
    
    init(oidcConfiguration: OidcConfiguration,
         encryptionKeyProvider: EncryptionKeyProviderProtocol,
         userSessionStore: UserSessionStoreProtocol) {
        self.oidcConfiguration = oidcConfiguration
        self.userSessionStore = userSessionStore
        passphrase = encryptionKeyProvider.generateKey().base64EncodedString()
    }
    
    func loginWithQRCode(data: Data) async -> Result<UserSessionProtocol, QRCodeLoginServiceError> {
        let qrData: QrCodeData
        do {
            qrData = try QrCodeData.fromBytes(bytes: data)
        } catch {
            MXLog.error("QRCode decode error: \(error)")
            return .failure(.invalidQRCode)
        }
        
        let listener = QrLoginProgressListenerProxy { [weak self] progress in
            self?.qrLoginProgressSubject.send(progress)
        }
        
        do {
            let client = try await ClientBuilder()
                .basePath(path: userSessionStore.baseDirectory.path(percentEncoded: false))
                .passphrase(passphrase: passphrase)
                .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
                .enableCrossProcessRefreshLock(processId: InfoPlistReader.main.bundleIdentifier,
                                               sessionDelegate: userSessionStore.clientSessionDelegate)
                .serverVersions(versions: ["v1.0", "v1.1", "v1.2", "v1.3", "v1.4", "v1.5"]) // FIXME: Quick and dirty fix for stopping version requests on startup https://github.com/matrix-org/matrix-rust-sdk/pull/1376
                .buildWithQrCode(qrCodeData: qrData, oidcConfiguration: oidcConfiguration, progressListener: listener)
            return await login(client: client)
        } catch let error as HumanQrLoginError {
            MXLog.error("QRCode login error: \(error)")
            return .failure(error.serviceError)
        } catch {
            MXLog.error("QRCode login unknown error: \(error)")
            return .failure(.unknown)
        }
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
    
    private func login(client: Client) async -> Result<UserSessionProtocol, QRCodeLoginServiceError> {
        switch await userSessionStore.userSession(for: client, passphrase: passphrase) {
        case .success(let session):
            return .success(session)
        case .failure(let error):
            MXLog.error("QRCode login failed error: \(error)")
            return .failure(.failedLoggingIn)
        }
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

private extension HumanQrLoginError {
    var serviceError: QRCodeLoginServiceError {
        switch self {
        case .Cancelled:
            return .cancelled
        case .ConnectionInsecure:
            return .connectionInsecure
        case .Declined:
            return .declined
        case .LinkingNotSupported:
            return .linkingNotSupported
        case .Expired:
            return .expired
        case .InvalidQrCode:
            return .invalidQRCode
        case .SlidingSyncNotAvailable:
            return .deviceNotSupported
        case .OtherDeviceNotSignedIn:
            return .deviceNotSignedIn
        case .Unknown, .OidcMetadataInvalid:
            return .unknown
        }
    }
}
