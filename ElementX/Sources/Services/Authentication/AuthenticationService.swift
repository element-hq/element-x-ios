//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class AuthenticationService: AuthenticationServiceProtocol {
    private var client: ClientProtocol?
    private var sessionDirectories: SessionDirectories
    private let passphrase: String
    
    private let clientFactory: AuthenticationClientFactoryProtocol
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks
    
    private let zeroAuthApiProxy: ZeroAuthApiProxyProtocol
    
    private let homeserverSubject: CurrentValueSubject<LoginHomeserver, Never>
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> { homeserverSubject.asCurrentValuePublisher() }
    private(set) var flow: AuthenticationFlow
    
    private let qrLoginProgressSubject = PassthroughSubject<QrLoginProgress, Never>()
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> {
        qrLoginProgressSubject.eraseToAnyPublisher()
    }
    
    init(userSessionStore: UserSessionStoreProtocol,
         encryptionKeyProvider: EncryptionKeyProviderProtocol,
         clientFactory: AuthenticationClientFactoryProtocol = AuthenticationClientFactory(),
         appSettings: AppSettings,
         appHooks: AppHooks) {
        sessionDirectories = .init()
        passphrase = encryptionKeyProvider.generateKey().base64EncodedString()
        self.clientFactory = clientFactory
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        self.appHooks = appHooks
        
        zeroAuthApiProxy = ZeroAuthApiProxy(appSettings: appSettings)
        
        // When updating these, don't forget to update the reset method too.
        homeserverSubject = .init(LoginHomeserver(address: appSettings.accountProviders[0], loginMode: .unknown))
        flow = .login
    }
    
    // MARK: - Public
    
    func configure(for homeserverAddress: String, flow: AuthenticationFlow) async -> Result<Void, AuthenticationServiceError> {
        do {
            var homeserver = LoginHomeserver(address: homeserverAddress, loginMode: .unknown)
            
            let client = try await makeClient(homeserverAddress: homeserverAddress)
            try await appHooks.elementWellKnownHook.validate(using: client).get()
            let loginDetails = await client.homeserverLoginDetails()
            
            MXLog.info("Sliding sync: \(client.slidingSyncVersion())")
            
            homeserver.loginMode = if loginDetails.supportsOidcLogin() {
                .oidc(supportsCreatePrompt: loginDetails.supportedOidcPrompts().contains(.create))
            } else if loginDetails.supportsPasswordLogin() {
                .password
            } else {
                .unsupported
            }
            
            if flow == .login, homeserver.loginMode == .unsupported {
                return .failure(.loginNotSupported)
            }
            if flow == .register, !homeserver.loginMode.supportsOIDCFlow {
                return .failure(.registrationNotSupported)
            }
            
            self.client = client
            self.flow = flow
            homeserverSubject.send(homeserver)
            return .success(())
        } catch ClientBuildError.WellKnownDeserializationError(let error) {
            MXLog.error("The user entered a server with an invalid well-known file: \(error)")
            return .failure(.invalidWellKnown(error))
        } catch ClientBuildError.SlidingSyncVersion(let error) {
            MXLog.info("User entered a homeserver that isn't configured for sliding sync: \(error)")
            return .failure(.slidingSyncNotAvailable)
        } catch ElementWellKnownError.elementProRequired(let serverName) {
            return .failure(.elementProRequired(serverName: serverName))
        } catch {
            MXLog.error("Failed configuring a server: \(error)")
            return .failure(.invalidHomeserverAddress)
        }
    }
    
    func urlForOIDCLogin(loginHint: String?) async -> Result<OIDCAuthorizationDataProxy, AuthenticationServiceError> {
        guard let client else { return .failure(.oidcError(.urlFailure)) }
        do {
            // The create prompt is broken: https://github.com/element-hq/matrix-authentication-service/issues/3429
            // let prompt: OidcPrompt = flow == .register ? .create : .consent
            let oidcData = try await client.urlForOidc(oidcConfiguration: appSettings.oidcConfiguration.rustValue,
                                                       prompt: .consent,
                                                       loginHint: loginHint,
                                                       deviceId: nil)
            return .success(OIDCAuthorizationDataProxy(underlyingData: oidcData))
        } catch {
            MXLog.error("Failed to get URL for OIDC login: \(error)")
            return .failure(.oidcError(.urlFailure))
        }
    }
    
    func abortOIDCLogin(data: OIDCAuthorizationDataProxy) async {
        guard let client else { return }
        MXLog.info("Aborting OIDC login.")
        await client.abortOidcAuth(authorizationData: data.underlyingData)
    }
    
    func loginWithOIDCCallback(_ callbackURL: URL) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            try await client.loginWithOidcCallback(callbackUrl: callbackURL.absoluteString)
            return await userSession(for: client)
        } catch OidcError.Cancelled {
            return .failure(.oidcError(.userCancellation))
        } catch {
            MXLog.error("Login with OIDC failed: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            let zeroMatrixSSOResult = try await zeroAuthApiProxy.authApi.loginSSO(email: username, password: password)
            switch zeroMatrixSSOResult {
            case .success(let zeroSSOToken):
                try await client.customLoginWithJwt(jwt: zeroSSOToken.token, initialDeviceName: initialDeviceName, deviceId: deviceID)
                
                try await checkAndLinkMatrixUser(client.userId())
            
                let refreshToken = try? client.session().refreshToken
                if refreshToken != nil {
                    MXLog.warning("Refresh token found for a non oidc session, can't restore session, logging out")
                    _ = try? await client.logout()
                    return .failure(.sessionTokenRefreshNotSupported)
                }
                StateBus.shared.onUserAuthStateChanged(.authorised)
                return await userSession(for: client)
            case .failure:
                return .failure(.failedLoggingIn)
            }
        } catch let ClientError.MatrixApi(errorKind, _, _, _) {
            MXLog.error("Failed logging in with error kind: \(errorKind)")
            switch errorKind {
            case .forbidden:
                return .failure(.invalidCredentials)
            case .userDeactivated:
                return .failure(.accountDeactivated)
            default:
                return .failure(.failedLoggingIn)
            }
        } catch {
            MXLog.error("Failed logging in with error: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    func loginWithWeb3(web3Token: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            let zeroMatrixSSOResult = try await zeroAuthApiProxy.authApi.loginWithWeb3(web3Token: web3Token)
            switch zeroMatrixSSOResult {
            case .success(let zeroSSOToken):
                try await client.customLoginWithJwt(jwt: zeroSSOToken.token, initialDeviceName: initialDeviceName, deviceId: deviceID)
                
                try await checkAndLinkMatrixUser(client.userId())
                
                let refreshToken = try? client.session().refreshToken
                if refreshToken != nil {
                    MXLog.warning("Refresh token found for a non oidc session, can't restore session, logging out")
                    _ = try? await client.logout()
                    return .failure(.sessionTokenRefreshNotSupported)
                }
                StateBus.shared.onUserAuthStateChanged(.authorised)
                return await userSession(for: client)
            case .failure(_):
                return .failure(.failedLoggingIn)
            }
        } catch let ClientError.MatrixApi(errorKind, _, _, _) {
            MXLog.error("Failed logging in with error kind: \(errorKind)")
            switch errorKind {
            case .forbidden:
                return .failure(.invalidCredentials)
            case .userDeactivated:
                return .failure(.accountDeactivated)
            default:
                return .failure(.failedLoggingIn)
            }
        } catch {
            MXLog.error("Failed logging in with error: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    func loginWithQRCode(data: Data) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        let qrData: QrCodeData
        do {
            qrData = try QrCodeData.fromBytes(bytes: data)
        } catch {
            MXLog.error("QRCode decode error: \(error)")
            return .failure(.qrCodeError(.invalidQRCode))
        }
        
        guard let scannedServerName = qrData.serverName() else {
            MXLog.error("The QR code is from a device that is not yet signed in.")
            return .failure(.qrCodeError(.deviceNotSignedIn))
        }
        
        if !appSettings.allowOtherAccountProviders, !appSettings.accountProviders.contains(scannedServerName) {
            MXLog.error("The scanned device's server is not allowed: \(scannedServerName)")
            return .failure(.qrCodeError(.providerNotAllowed(scannedProvider: scannedServerName, allowedProviders: appSettings.accountProviders)))
        }
        
        let listener = SDKListener { [weak self] progress in
            self?.qrLoginProgressSubject.send(progress)
        }
        
        do {
            let client = try await makeClient(homeserverAddress: scannedServerName)
            try await appHooks.elementWellKnownHook.validate(using: client).get()
            try await client.loginWithQrCode(qrCodeData: qrData,
                                             oidcConfiguration: appSettings.oidcConfiguration.rustValue,
                                             progressListener: listener)
            MXLog.info("Sliding sync: \(client.slidingSyncVersion())")
            return await userSession(for: client)
        } catch let error as HumanQrLoginError {
            MXLog.error("QRCode login error: \(error)")
            return .failure(error.serviceError)
        } catch ElementWellKnownError.elementProRequired(let serverName) {
            return .failure(.elementProRequired(serverName: serverName))
        } catch {
            MXLog.error("QRCode login unknown error: \(error)")
            return .failure(.qrCodeError(.unknown))
        }
    }
    
    func reset() {
        homeserverSubject.send(LoginHomeserver(address: appSettings.accountProviders[0], loginMode: .unknown))
        flow = .login
        client = nil
    }
    
    func verifyCreateAccountInviteCode(inviteCode: String) async -> Result<Void, AuthenticationServiceError> {
        do {
            let result = try await zeroAuthApiProxy.createAccountApi.validateInviteCode(inviteCode: inviteCode)
            switch result {
            case .success:
                return .success(())
            case .failure:
                return .failure(.invalidInviteCode)
            }
        } catch {
            MXLog.error(error)
            return .failure(.invalidInviteCode)
        }
    }
    
    func createUserAccount(email: String, password: String, inviteCode: String) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        do {
            let result = try await zeroAuthApiProxy.createAccountApi.createAccountWithEmail(email: email, password: password, invite: inviteCode)
            switch result {
            case .success:
                await ensureHomeServerIsConfigured()
                let session = await loginNewlyCreatedUser()
                
                try await checkAndLinkMatrixUser(client?.userId(), fromCreateAccountFlow: true)
                
                switch session {
                case .success(let userSession):
                    return .success(userSession)
                case .failure:
                    return .failure(.failedCreatingUserAccount)
                }
            case .failure:
                return .failure(.failedCreatingUserAccount)
            }
        } catch {
            MXLog.error(error)
            return .failure(.failedCreatingUserAccount)
        }
    }
    
    func createUserAccountWithWeb3(web3Token: String, inviteCode: String) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        do {
            let result = try await zeroAuthApiProxy.createAccountApi.createAccountWithWeb3(web3Token: web3Token, invite: inviteCode)
            switch result {
            case .success(_):
                await ensureHomeServerIsConfigured()
                let session = await loginNewlyCreatedUser()
                
                try await checkAndLinkMatrixUser(client?.userId(), fromCreateAccountFlow: true)
                
                switch session {
                case .success(let userSession):
                    return .success(userSession)
                case .failure(_):
                    return .failure(.failedCreatingUserAccount)
                }
            case .failure(_):
                return .failure(.failedCreatingUserAccount)
            }
        } catch {
            MXLog.error(error)
            return .failure(.failedCreatingUserAccount)
        }
    }
    
    // MARK: - Private
    
    private func makeClient(homeserverAddress: String) async throws -> ClientProtocol {
        // Use a fresh session directory each time the user enters a different server
        // so that caches (e.g. server versions) are always fresh for the new server.
        rotateSessionDirectory()
        
        return try await clientFactory.makeClient(homeserverAddress: homeserverAddress,
                                                  sessionDirectories: sessionDirectories,
                                                  passphrase: passphrase,
                                                  clientSessionDelegate: userSessionStore.clientSessionDelegate,
                                                  appSettings: appSettings,
                                                  appHooks: appHooks)
    }
    
    private func rotateSessionDirectory() {
        sessionDirectories.delete()
        sessionDirectories = .init()
    }
    
    private func userSession(for client: ClientProtocol) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        switch await userSessionStore.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: passphrase) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
    
    private func ensureHomeServerIsConfigured() async {
        if client == nil {
            _ = await configure(for: appSettings.accountProviders[0], flow: .login)
        }
    }
    
    private func loginNewlyCreatedUser() async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            let zeroMatrixSSOResult = try await zeroAuthApiProxy.authApi.fetchSSOToken()
            switch zeroMatrixSSOResult {
            case .success(let zeroSSOToken):
                try await client.customLoginWithJwt(jwt: zeroSSOToken.token, initialDeviceName: nil, deviceId: nil)
                
                let refreshToken = try? client.session().refreshToken
                if refreshToken != nil {
                    MXLog.warning("Refresh token found for a non oidc session, can't restore session, logging out")
                    _ = try? await client.logout()
                    return .failure(.sessionTokenRefreshNotSupported)
                }
                StateBus.shared.onUserAuthStateChanged(.authorised)
                return await userSession(for: client)
            case .failure:
                return .failure(.failedLoggingIn)
            }
        } catch {
            MXLog.error(error)
            return .failure(.failedLoggingIn)
        }
    }
    
    private func checkAndLinkMatrixUser(_ userId: String?, fromCreateAccountFlow: Bool = false) async throws {
        guard let userId else { return }
        
        let currentUserResult = try await zeroAuthApiProxy.usersApi.fetchCurrentUser()
        switch currentUserResult {
        case .success(let currentUser):
            if fromCreateAccountFlow || currentUser.matrixId == nil {
                _ = try await zeroAuthApiProxy.authApi.linkMatrixUserToZero(matrixUserId: userId)
            }
        case .failure(let failure):
            MXLog.failure("Failed to fetch current zero user. Error: \(failure)")
        }
    }
}

private extension HumanQrLoginError {
    var serviceError: AuthenticationServiceError {
        switch self {
        case .Cancelled:
            .qrCodeError(.cancelled)
        case .ConnectionInsecure:
            .qrCodeError(.connectionInsecure)
        case .Declined:
            .qrCodeError(.declined)
        case .LinkingNotSupported:
            .qrCodeError(.linkingNotSupported)
        case .Expired:
            .qrCodeError(.expired)
        case .SlidingSyncNotAvailable:
            .qrCodeError(.deviceNotSupported)
        case .OtherDeviceNotSignedIn:
            .qrCodeError(.deviceNotSignedIn)
        case .Unknown, .OidcMetadataInvalid:
            .qrCodeError(.unknown)
        }
    }
}

// MARK: - Mocks

extension AuthenticationService {
    static var mock: AuthenticationService {
        AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                              encryptionKeyProvider: EncryptionKeyProvider(),
                              clientFactory: AuthenticationClientFactoryMock(configuration: .init()),
                              appSettings: ServiceLocator.shared.settings,
                              appHooks: AppHooks())
    }
}
