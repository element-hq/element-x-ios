//
//  UserSession.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

class UserSession: UserSessionProtocol {
    private var cancellables = Set<AnyCancellable>()
    
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        
        setupSessionVerificationWatchdog()
    }
    
    // MARK: - Private
    
    private func setupSessionVerificationWatchdog() {
        clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                if case .receivedSyncUpdate = callback {
                    self?.attemptSessionVerification()
                }
            }.store(in: &cancellables)
    }
    
    private func attemptSessionVerification() {
        Task {
            switch await clientProxy.getSessionVerificationControllerProxy() {
            case .success(let sessionVerificationController):
                tearDownSessionVerificationWatchdog()
                
                if !sessionVerificationController.isVerified {
                    callbacks.send(.sessionVerificationNeeded)
                }
            case .failure(let error):
                MXLog.error("Failed getting session verification controller with error: \(error). Will retry on the next sync update.")
            }
        }
    }
    
    private func tearDownSessionVerificationWatchdog() {
        cancellables.removeAll()
    }
}
