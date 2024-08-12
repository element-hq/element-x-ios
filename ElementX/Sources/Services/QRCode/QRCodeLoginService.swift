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

import Combine
import Foundation

import MatrixRustSDK

final class QRCodeLoginService: QRCodeLoginServiceProtocol {
    private var sessionDirectory: URL
    private let passphrase: String
    
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks
    
    private let qrLoginProgressSubject = PassthroughSubject<QrLoginProgress, Never>()
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> {
        qrLoginProgressSubject.eraseToAnyPublisher()
    }
    
    init(encryptionKeyProvider: EncryptionKeyProviderProtocol,
         userSessionStore: UserSessionStoreProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks) {
        sessionDirectory = .sessionsBaseDirectory.appending(component: UUID().uuidString)
        passphrase = encryptionKeyProvider.generateKey().base64EncodedString()
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        self.appHooks = appHooks
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
            let client = try await makeClientBuilder().buildWithQrCode(qrCodeData: qrData,
                                                                       oidcConfiguration: appSettings.oidcConfiguration.rustValue,
                                                                       progressListener: listener)
            return await userSession(for: client)
        } catch let error as HumanQrLoginError {
            MXLog.error("QRCode login error: \(error)")
            return .failure(error.serviceError)
        } catch {
            MXLog.error("QRCode login unknown error: \(error)")
            return .failure(.unknown)
        }
    }
    
    // MARK: - Private
    
    private func makeClientBuilder() -> ClientBuilder {
        // Use a fresh session directory each time the user scans a QR code to ensure caches
        // (e.g. server versions) are always fresh in case a different server is used.
        rotateSessionDirectory()
        
        return ClientBuilder
            .baseBuilder(httpProxy: appSettings.websiteURL.globalProxy,
                         slidingSync: appSettings.simplifiedSlidingSyncEnabled ? .simplified : .discovered,
                         slidingSyncProxy: appSettings.slidingSyncProxyURL,
                         sessionDelegate: userSessionStore.clientSessionDelegate,
                         appHooks: appHooks)
            .sessionPath(path: sessionDirectory.path(percentEncoded: false))
            .passphrase(passphrase: passphrase)
    }
    
    private func rotateSessionDirectory() {
        if FileManager.default.directoryExists(at: sessionDirectory) {
            try? FileManager.default.removeItem(at: sessionDirectory)
        }
        
        sessionDirectory = .sessionsBaseDirectory.appending(component: UUID().uuidString)
    }
    
    private func userSession(for client: Client) async -> Result<UserSessionProtocol, QRCodeLoginServiceError> {
        switch await userSessionStore.userSession(for: client, sessionDirectory: sessionDirectory, passphrase: passphrase) {
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
        case .SlidingSyncNotAvailable:
            return .deviceNotSupported
        case .OtherDeviceNotSignedIn:
            return .deviceNotSignedIn
        case .Unknown, .OidcMetadataInvalid:
            return .unknown
        }
    }
}
