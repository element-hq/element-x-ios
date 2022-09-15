//
// Copyright 2022 New Vector Ltd
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

class UserSession: UserSessionProtocol {
    private var cancellables = Set<AnyCancellable>()
    private var checkForSessionVerificationControllerCancellable: AnyCancellable?
    private var authErrorCancellable: AnyCancellable?
    private var restoreTokenUpdateCancellable: AnyCancellable?
    
    var userID: String { clientProxy.userIdentifier }
    var isSoftLogout: Bool { clientProxy.isSoftLogout }
    var deviceId: String? { clientProxy.deviceId }
    var homeserver: String { clientProxy.homeserver }

    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    private(set) var sessionVerificationController: SessionVerificationControllerProxyProtocol?
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        
        setupSessionVerificationWatchdog()
        setupAuthErrorWatchdog()
        setupRestoreTokenUpdateWatchdog()
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

    // MARK: Auth Error Watchdog

    private func setupAuthErrorWatchdog() {
        authErrorCancellable = clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                if case .receivedAuthError(let isSoftLogout) = callback {
                    self?.callbacks.send(.didReceiveAuthError(isSoftLogout: isSoftLogout))
                    self?.tearDownAuthErrorWatchdog()
                }
            }
    }

    private func tearDownAuthErrorWatchdog() {
        authErrorCancellable = nil
    }

    // MARK: Restore Token Update Watchdog

    private func setupRestoreTokenUpdateWatchdog() {
        restoreTokenUpdateCancellable = clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                if case .updatedRestoreToken = callback {
                    self?.callbacks.send(.updateRestoreTokenNeeded)
                    self?.tearDownRestoreTokenUpdateWatchdog()
                }
            }
    }

    private func tearDownRestoreTokenUpdateWatchdog() {
        restoreTokenUpdateCancellable = nil
    }
}
