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

import SwiftUI

typealias SessionVerificationViewModelType = StateStoreViewModel<SessionVerificationScreenViewState, SessionVerificationScreenViewAction>

class SessionVerificationScreenViewModel: SessionVerificationViewModelType, SessionVerificationScreenViewModelProtocol {
    private let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
    
    private var stateMachine: SessionVerificationScreenStateMachine

    var callback: ((SessionVerificationScreenViewModelAction) -> Void)?

    init(sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol,
         initialState: SessionVerificationScreenViewState = SessionVerificationScreenViewState()) {
        self.sessionVerificationControllerProxy = sessionVerificationControllerProxy
        
        stateMachine = SessionVerificationScreenStateMachine()
        
        super.init(initialViewState: initialState)
        
        setupStateMachine()
        
        sessionVerificationControllerProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .acceptedVerificationRequest:
                    self.stateMachine.processEvent(.didAcceptVerificationRequest)
                case .startedSasVerification:
                    self.stateMachine.processEvent(.didStartSasVerification)
                case .receivedVerificationData(let emojis):
                    guard self.stateMachine.state == .sasVerificationStarted else {
                        MXLog.warning("Callbacks: Ignoring receivedVerificationData due to invalid state.")
                        return
                    }
                    
                    self.stateMachine.processEvent(.didReceiveChallenge(emojis: emojis))
                case .finished:
                    self.stateMachine.processEvent(.didAcceptChallenge)
                case .cancelled:
                    self.stateMachine.processEvent(.didCancel)
                case .failed:
                    self.stateMachine.processEvent(.didFail)
                }
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: SessionVerificationScreenViewAction) {
        switch viewAction {
        case .requestVerification:
            stateMachine.processEvent(.requestVerification)
        case .startSasVerification:
            stateMachine.processEvent(.startSasVerification)
        case .restart:
            stateMachine.processEvent(.restart)
        case .close:
            guard stateMachine.state == .initial ||
                stateMachine.state == .verified ||
                stateMachine.state == .cancelled else {
                stateMachine.processEvent(.cancel)
                return
            }
            
            callback?(.finished)
        case .accept:
            stateMachine.processEvent(.acceptChallenge)
        case .decline:
            stateMachine.processEvent(.declineChallenge)
        }
    }
    
    // MARK: - Private
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
                
            self.state.verificationState = context.toState
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .requestVerification, .requestingVerification):
                self.requestVerification()
            case (.verificationRequestAccepted, .startSasVerification, .startingSasVerification):
                self.startSasVerification()
            case (.showingChallenge, .acceptChallenge, .acceptingChallenge):
                self.acceptChallenge()
            case (.showingChallenge, .declineChallenge, .decliningChallenge):
                self.declineChallenge()
            case (_, .cancel, .cancelling):
                self.cancelVerification()
            case (_, _, .verified):
                // Dismiss the success screen automatically.
                Task {
                    do {
                        try await Task.sleep(for: .seconds(2))
                    } catch {
                        MXLog.error(error.localizedDescription)
                    }
                    self.callback?(.finished)
                }
            default:
                break
            }
        }
        
        stateMachine.addErrorHandler { context in
            MXLog.error("Failed transition with context: \(context)")
        }
    }
    
    private func requestVerification() {
        Task {
            switch await sessionVerificationControllerProxy.requestVerification() {
            case .success:
                // Need to wait for the callback from the remote
                break
            case .failure:
                stateMachine.processEvent(.didFail)
            }
        }
    }
    
    private func cancelVerification() {
        Task {
            switch await sessionVerificationControllerProxy.cancelVerification() {
            case .success:
                stateMachine.processEvent(.didCancel)
            case .failure:
                stateMachine.processEvent(.didFail)
            }
        }
    }
    
    private func startSasVerification() {
        Task {
            switch await sessionVerificationControllerProxy.startSasVerification() {
            case .success:
                // Need to wait for the callback from the remote
                break
            case .failure:
                stateMachine.processEvent(.didFail)
            }
        }
    }
    
    private func acceptChallenge() {
        Task {
            switch await sessionVerificationControllerProxy.approveVerification() {
            case .success:
                // Need to wait for the callback from the remote
                break
            case .failure:
                stateMachine.processEvent(.didFail)
            }
        }
    }
    
    private func declineChallenge() {
        Task {
            switch await sessionVerificationControllerProxy.declineVerification() {
            case .success:
                stateMachine.processEvent(.didCancel)
            case .failure:
                stateMachine.processEvent(.didFail)
            }
        }
    }
}
