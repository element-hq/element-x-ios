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
    private let sessionVerificationStateSubject: CurrentValueSubject<SessionVerificationState, Never> = .init(.unknown)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var checkSessionVerificationStateCancellable: AnyCancellable?
    private var retrieveSessionVerificationControllerTask: Task<Void, Never>?
    
    private var authErrorCancellable: AnyCancellable?
    
    var userID: String { clientProxy.userID }
    var deviceID: String? { clientProxy.deviceID }
    var homeserver: String { clientProxy.homeserver }

    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    private(set) var sessionVerificationController: SessionVerificationControllerProxyProtocol? {
        didSet {
            sessionVerificationController?.callbacks.sink { [weak self] callback in
                switch callback {
                case .finished:
                    self?.sessionVerificationStateSubject.send(.verified)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        }
    }
    
    private var sessionSecurityStateSubject: CurrentValueSubject<SessionSecurityState, Never> = .init(.init(verificationState: .unknown, recoveryState: .unknown))
    var sessionSecurityState: CurrentValuePublisher<SessionSecurityState, Never> {
        sessionSecurityStateSubject.asCurrentValuePublisher()
    }
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol, voiceMessageMediaManager: VoiceMessageMediaManagerProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.voiceMessageMediaManager = voiceMessageMediaManager
        
        clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                if callback.isSyncUpdate {
                    self?.checkSessionVerificationState()
                }
            }
            .store(in: &cancellables)
        
        authErrorCancellable = clientProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .receivedAuthError(let isSoftLogout):
                    callbacks.send(.didReceiveAuthError(isSoftLogout: isSoftLogout))
                    authErrorCancellable = nil
                default:
                    break
                }
            }
        
        Publishers.CombineLatest(sessionVerificationStateSubject, clientProxy.secureBackupController.recoveryState)
            .removeDuplicates { $0 == $1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verificationState, recoveryState in
                
                MXLog.info("Session security state changed, verificationState: \(verificationState), recoveryState: \(recoveryState)")
                
                self?.sessionSecurityStateSubject.send(.init(verificationState: verificationState, recoveryState: recoveryState))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private
        
    private func checkSessionVerificationState() {
        guard retrieveSessionVerificationControllerTask == nil else {
            MXLog.info("Session verification state check already in progress")
            return
        }
        
        guard sessionVerificationController == nil else {
            Task {
                await updateSessionVerificationState()
            }
            return
        }
        
        MXLog.info("Retrieving session verification controller")
        
        retrieveSessionVerificationControllerTask = Task {
            switch await clientProxy.sessionVerificationControllerProxy() {
            case .success(let sessionVerificationController):
                self.sessionVerificationController = sessionVerificationController
                await updateSessionVerificationState()
                
                retrieveSessionVerificationControllerTask = nil
            case .failure(let error):
                MXLog.info("Failed getting session verification controller with error: \(error). Will retry on the next sync update.")
            }
        }
    }
    
    private func updateSessionVerificationState() async {
        guard let sessionVerificationController else {
            fatalError("This point should never be reached")
        }
        
        MXLog.info("Checking session verification state")
        
        guard case let .success(isVerified) = await sessionVerificationController.isVerified() else {
            MXLog.error("Failed checking verification state. Will retry on the next sync update.")
            return
        }
        
        if isVerified {
            sessionVerificationStateSubject.send(.verified)
        } else {
            guard case let .success(isLastDevice) = await clientProxy.isOnlyDeviceLeft() else {
                MXLog.error("Failed checking isLastDevice. Will retry on the next sync update.")
                return
            }
            
            if isLastDevice {
                sessionVerificationStateSubject.send(.unverifiedLastSession)
            } else {
                sessionVerificationStateSubject.send(.unverified)
            }
        }
    }
}
