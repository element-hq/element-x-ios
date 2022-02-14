//
//  AuthenticationCoordinator.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11.02.2022.
//

import Foundation
import MatrixRustSDK

enum AuthenticationCoordinatorError: Error {
    case failedLoggingIn
    case failedRestoringLogin
    case failedSettingUpSession
}

protocol AuthenticationCoordinatorDelegate: AnyObject {
    func authenticationCoordinatorDidSetupUserSession(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinatorDidTearDownUserSession(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didFailWithError error: AuthenticationCoordinatorError)
}

class AuthenticationCoordinator: Coordinator {
    
    private let keychainController: KeychainControllerProtocol
    private let navigationRouter: NavigationRouter
    
    private(set) var userSession: UserSession?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(keychainController: KeychainControllerProtocol,
         navigationRouter: NavigationRouter) {
        self.keychainController =  keychainController
        self.navigationRouter = navigationRouter
    }
    
    func start() {
        let availableRestoreTokens = keychainController.restoreTokens()
        
        guard let usernameTokenTuple = availableRestoreTokens.first else {
            startNewLoginFlow()
            return
        }
        
        restorePreviousLogin(usernameTokenTuple)
    }
    
    // MARK: - Private
    
    private func startNewLoginFlow() {
        let parameters = LoginScreenCoordinatorParameters()
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            switch result {
            case .login(let result):
                do {
                    self.setupUserSessionForClient(try loginNewClient(basePath: self.baseDirectoryPathForUsername(result.username),
                                                                      username: result.username,
                                                                      password: result.password))
                    
                    self.remove(childCoordinator: coordinator)
                    self.navigationRouter.dismissModule()
                } catch {
                    self.delegate?.authenticationCoordinator(self, didFailWithError: .failedLoggingIn)
                    MXLog.error("Failed logging in user with error: \(error)")
                }
            }
        }
        
        add(childCoordinator: coordinator)
        navigationRouter.present(coordinator)
        
        coordinator.start()
    }
    
    private func restorePreviousLogin(_ usernameTokenTuple: (username: String, token: String)) {
        do {
            setupUserSessionForClient(try loginWithToken(basePath: baseDirectoryPathForUsername(usernameTokenTuple.username),
                                                         restoreToken: usernameTokenTuple.token))
        } catch {
            delegate?.authenticationCoordinator(self, didFailWithError: .failedRestoringLogin)
            MXLog.error("Failed restoring login with error: \(error)")
        }
    }
    
    private func setupUserSessionForClient(_ client: Client) {
        
        do {
            let restoreToken = try client.restoreToken()
            let userId = try client.userId()
            
            keychainController.setRestoreToken(restoreToken, forUsername: userId)
        } catch {
            delegate?.authenticationCoordinator(self, didFailWithError: .failedSettingUpSession)
            MXLog.error("Failed setting up user session with error: \(error)")
        }
        
        userSession = UserSession(client: client)
        delegate?.authenticationCoordinatorDidSetupUserSession(self)
    }
    
    private func baseDirectoryPathForUsername(_ username: String) -> String {
        guard var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Should always be able to retrieve the caches directory")
        }
        
        url = url.appendingPathComponent(username)
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        
        return url.path
    }
}
