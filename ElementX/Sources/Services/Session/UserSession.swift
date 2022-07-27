//
//  UserSession.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import Foundation

class UserSession: UserSessionProtocol {
    private var cancellables = Set<AnyCancellable>()
    private var checkForSessionVerificationControllerCancellable: AnyCancellable?
    
    var userID: String { clientProxy.userIdentifier }
    
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    private(set) var sessionVerificationController: SessionVerificationControllerProxyProtocol?
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        
        setupSessionVerificationWatchdog()
    }
    
    // MARK: - Private
    
    private func setupSessionVerificationWatchdog() {
        checkForSessionVerificationControllerCancellable = clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                if case .receivedSyncUpdate = callback {
                    self?.attemptSessionVerification()
                }
            }
    }
    
    private func attemptSessionVerification() {
        Task {
            switch await clientProxy.sessionVerificationControllerProxy() {
            case .success(let sessionVerificationController):
                tearDownSessionVerificationControllerWatchdog()
                
                if !sessionVerificationController.isVerified {
                    callbacks.send(.sessionVerificationNeeded)
                }
                
                self.sessionVerificationController = sessionVerificationController
                
                sessionVerificationController.callbacks.sink { callback in
                    switch callback {
                    case .finished:
                        self.callbacks.send(.didVerifySession)
                    default:
                        break
                    }
                }.store(in: &cancellables)
                
            case .failure(let error):
                MXLog.error("Failed getting session verification controller with error: \(error). Will retry on the next sync update.")
            }
        }
    }
    
    private func tearDownSessionVerificationControllerWatchdog() {
        checkForSessionVerificationControllerCancellable = nil
    }
}
