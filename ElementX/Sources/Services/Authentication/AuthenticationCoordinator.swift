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
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator)
    
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
            startNewLoginFlow { result in
                switch result {
                case .success:
                    self.delegate?.authenticationCoordinatorDidSetupUserSession(self)
                case .failure(let error):
                    self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                    MXLog.error("Failed logging in user with error: \(error)")
                }
            }
            return
        }
        
        restorePreviousLogin(usernameTokenTuple) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.delegate?.authenticationCoordinatorDidSetupUserSession(self)
            case .failure(let error):
                self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                MXLog.error("Failed restoring login with error: \(error)")
                
                // On any restoration failure reset the token and restart
                self.keychainController.removeAllTokens()
                self.start()
            }
        }
    }
    
    func logout() {
        keychainController.removeAllTokens()
        
        if let userIdentifier = userSession?.userIdentifier {
            deleteBaseDirectoryForUsername(userIdentifier)
        }
        
        userSession = nil
        
        delegate?.authenticationCoordinatorDidTearDownUserSession(self)
    }
    
    // MARK: - Private
    
    private func startNewLoginFlow(_ completion: @escaping (Result<(), AuthenticationCoordinatorError>) -> Void) {
        let parameters = LoginScreenCoordinatorParameters()
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            switch result {
            case .login(let result):
                self.login(username: result.username, password: result.password) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success:
                        completion(.success(()))
                        self.remove(childCoordinator: coordinator)
                        self.navigationRouter.dismissModule()
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
        
        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator)
        
        coordinator.start()
    }
    
    private func login(username: String, password: String, completion: @escaping (Result<Void, AuthenticationCoordinatorError>) -> Void) {
        Benchmark.startTrackingForIdentifier("Login", message: "Started new login")
        
        delegate?.authenticationCoordinatorDidStartLoading(self)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                self.setupUserSessionForClient(try loginNewClient(basePath: self.baseDirectoryPathForUsername(username),
                                                                  username: username,
                                                                  password: password))
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                MXLog.error("Failed logging in with error: \(error)")
                
                DispatchQueue.main.async {
                    completion(.failure(.failedLoggingIn))
                }
            }
        }
    }
    
    private func restorePreviousLogin(_ usernameTokenTuple: (username: String, token: String), completion: @escaping (Result<Void, AuthenticationCoordinatorError>) -> Void) {
        Benchmark.startTrackingForIdentifier("Login", message: "Started restoring previous login")
        
        delegate?.authenticationCoordinatorDidStartLoading(self)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                self.setupUserSessionForClient(try loginWithToken(basePath: self.baseDirectoryPathForUsername(usernameTokenTuple.username),
                                                                  restoreToken: usernameTokenTuple.token))
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                MXLog.error("Failed restoring login with error: \(error)")
                
                DispatchQueue.main.async {
                    completion(.failure(.failedRestoringLogin))
                }
            }
        }
    }
    
    private func setupUserSessionForClient(_ client: Client) {
        Benchmark.endTrackingForIdentifier("Login", message: "Finished login")
        
        do {
            let restoreToken = try client.restoreToken()
            let userId = try client.userId()
            
            keychainController.setRestoreToken(restoreToken, forUsername: userId)
        } catch {
            delegate?.authenticationCoordinator(self, didFailWithError: .failedSettingUpSession)
            MXLog.error("Failed setting up user session with error: \(error)")
        }
        
        userSession = UserSession(client: client)
    }
    
    private func baseDirectoryPathForUsername(_ username: String) -> String {
        guard var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Should always be able to retrieve the caches directory")
        }
        
        url = url.appendingPathComponent(username)
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        
        return url.path
    }
    
    private func deleteBaseDirectoryForUsername(_ username: String) {
        guard var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Should always be able to retrieve the caches directory")
        }
        
        url = url.appendingPathComponent(username)

        try? FileManager.default.removeItem(at: url)
    }
}
