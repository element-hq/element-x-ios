//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SessionVerificationViewModelType = StateStoreViewModel<SessionVerificationScreenViewState, SessionVerificationScreenViewAction>

class SessionVerificationScreenViewModel: SessionVerificationViewModelType, SessionVerificationScreenViewModelProtocol {
    private let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
    
    private var stateMachine: SessionVerificationScreenStateMachine

    private var actionsSubject: PassthroughSubject<SessionVerificationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SessionVerificationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol,
         verificationState: SessionVerificationScreenStateMachine.State = .initial) {
        self.sessionVerificationControllerProxy = sessionVerificationControllerProxy
        
        stateMachine = SessionVerificationScreenStateMachine()
        
        super.init(initialViewState: .init(verificationState: verificationState))
        
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
        case .accept:
            stateMachine.processEvent(.acceptChallenge)
        case .decline:
            stateMachine.processEvent(.declineChallenge)
        }
    }
    
    func stop() {
        let uncancellableStates: [SessionVerificationScreenStateMachine.State] = [.initial, .verified, .cancelled]
        
        if !uncancellableStates.contains(stateMachine.state) {
            stateMachine.processEvent(.cancel)
        }
    }
    
    // MARK: - Private
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
                
            state.verificationState = context.toState
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .requestVerification, .requestingVerification):
                requestVerification()
            case (.verificationRequestAccepted, .startSasVerification, .startingSasVerification):
                startSasVerification()
            case (.showingChallenge, .acceptChallenge, .acceptingChallenge):
                acceptChallenge()
            case (.showingChallenge, .declineChallenge, .decliningChallenge):
                declineChallenge()
            case (_, .cancel, .cancelling):
                cancelVerification()
            case (_, _, .verified):
                actionsSubject.send(.finished)
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
