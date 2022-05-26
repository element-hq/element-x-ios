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

@MainActor
protocol AuthenticationCoordinatorDelegate: AnyObject {
    
    func authenticationCoordinatorDidStartLoading(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinatorDidSetupClientProxy(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinatorDidTearDownClientProxy(_ authenticationCoordinator: AuthenticationCoordinator)
    
    func authenticationCoordinator(_ authenticationCoordinator: AuthenticationCoordinator,
                                   didFailWithError error: AuthenticationCoordinatorError)
}

class AuthenticationCoordinator: Coordinator {
    
    private let keychainController: KeychainControllerProtocol
    private let navigationRouter: NavigationRouter
    
    private(set) var clientProxy: ClientProxyProtocol?
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AuthenticationCoordinatorDelegate?
    
    init(keychainController: KeychainControllerProtocol,
         navigationRouter: NavigationRouter) {
        self.keychainController =  keychainController
        self.navigationRouter = navigationRouter
    }
    
    func start() {
        
        let availableAccessTokens = keychainController.accessTokens()
        
        guard let usernameTokenTuple = availableAccessTokens.first else {
            startNewLoginFlow { result in
                switch result {
                case .success:
                    self.delegate?.authenticationCoordinatorDidSetupClientProxy(self)
                case .failure(let error):
                    self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                    MXLog.error("Failed logging in user with error: \(error)")
                }
            }
            return
        }
        
        Task {
            switch await restorePreviousLogin(usernameTokenTuple) {
            case .success:
                self.delegate?.authenticationCoordinatorDidSetupClientProxy(self)
            case .failure(let error):
                self.delegate?.authenticationCoordinator(self, didFailWithError: error)
                MXLog.error("Failed restoring login with error: \(error)")
                
                // On any restoration failure reset the token and restart
                self.keychainController.removeAllAccessTokens()
                self.start()
            }
        }
    }
        
    func logout() {
        keychainController.removeAllAccessTokens()
        
        if let userIdentifier = clientProxy?.userIdentifier {
            deleteBaseDirectoryForUsername(userIdentifier)
        }
        
        clientProxy = nil
        
        delegate?.authenticationCoordinatorDidTearDownClientProxy(self)
    }
    
    // MARK: - Private
    
    private func startNewLoginFlow(_ completion: @escaping (Result<(), AuthenticationCoordinatorError>) -> Void) {
        let parameters = LoginScreenCoordinatorParameters()
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else {
                return
            }
            
            switch result {
            case .login(let result):
                Task {
                    switch await self.login(username: result.username, password: result.password) {
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
    
    private func login(username: String, password: String) async -> Result<Void, AuthenticationCoordinatorError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started new login")
        
        delegate?.authenticationCoordinatorDidStartLoading(self)
        
        let basePath = baseDirectoryPathForUsername(username)
        let loginTask = Task.detached {
            try loginNewClient(basePath: basePath,
                               username: username,
                               password: password)
        }
        
        switch await loginTask.result {
        case .success(let client):
            return await setupProxyForClient(client)
        case .failure(let error):
            MXLog.error("Failed logging in with error: \(error)")
            return .failure(.failedLoggingIn)
        }
    }
    
    private func restorePreviousLogin(_ usernameTokenTuple: (username: String, accessToken: String)) async -> Result<Void, AuthenticationCoordinatorError> {
        Benchmark.startTrackingForIdentifier("Login", message: "Started restoring previous login")
        
        delegate?.authenticationCoordinatorDidStartLoading(self)
        
        let basePath = baseDirectoryPathForUsername(usernameTokenTuple.username)
        let loginTask = Task.detached {
            try loginWithToken(basePath: basePath,
                               restoreToken: usernameTokenTuple.accessToken)
        }
        
        switch await loginTask.result {
        case .success(let client):
            return await setupProxyForClient(client)
        case .failure(let error):
            MXLog.error("Failed restoring login with error: \(error)")
            return .failure(.failedRestoringLogin)
        }
    }
    
    private func setupProxyForClient(_ client: Client) async -> Result<Void, AuthenticationCoordinatorError> {
        Benchmark.endTrackingForIdentifier("Login", message: "Finished login")
        
        do {
            let accessToken = try client.restoreToken()
            let userId = try client.userId()
            
            keychainController.setAccessToken(accessToken, forUsername: userId)
        } catch {
            MXLog.error("Failed setting up user session with error: \(error)")
            return .failure(.failedSettingUpSession)
        }
        
        clientProxy = ClientProxy(client: client)
        
        return .success(())
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
