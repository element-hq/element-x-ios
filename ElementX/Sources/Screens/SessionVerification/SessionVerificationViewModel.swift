//
// Copyright 2021 New Vector Ltd
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

typealias SessionVerificationViewModelType = StateStoreViewModel<SessionVerificationViewState, SessionVerificationViewAction>

class SessionVerificationViewModel: SessionVerificationViewModelType, SessionVerificationViewModelProtocol {

    // MARK: - Properties

    // MARK: Private
    
    private let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
    
    private var stateMachine: SessionVerificationStateMachine

    // MARK: Public

    var callback: ((SessionVerificationViewModelAction) -> Void)?

    // MARK: - Setup

    init(sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol,
         initialState: SessionVerificationViewState = SessionVerificationViewState()) {
        
        self.sessionVerificationControllerProxy = sessionVerificationControllerProxy
        
        stateMachine = SessionVerificationStateMachine()
        
        super.init(initialViewState: initialState)
        
        setupStateMachine()
        
        sessionVerificationControllerProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self = self else { return }
                
                switch callback {
                case .receivedVerificationData(let emojis):
                    self.stateMachine.processEvent(.didReceiveChallenge(emojis: emojis))
                case .finished:
                    self.stateMachine.processEvent(.didAcceptChallenge)
                case .cancelled:
                    self.stateMachine.processEvent(.didCancel)
                case .failed:
                    self.stateMachine.processEvent(.didFail)
                }
            }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SessionVerificationViewAction) async {
        switch viewAction {
        case .start:
            stateMachine.processEvent(.requestVerification)
        case .restart:
            stateMachine.processEvent(.restart)
        case .dismiss:
            callback?(.finished)
        case .cancel:
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
            guard let self = self else { return }
                
            self.state.verificationState = context.toState
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .requestVerification, .requestingVerification):
                self.requestVerification()
            case (.showingChallenge, .acceptChallenge, .acceptingChallenge):
                self.acceptChallenge()
            case (.showingChallenge, .declineChallenge, .decliningChallenge):
                self.declineChallenge()
            case (_, .cancel, .cancelling):
                self.cancelVerification()
            default:
                break
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
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
