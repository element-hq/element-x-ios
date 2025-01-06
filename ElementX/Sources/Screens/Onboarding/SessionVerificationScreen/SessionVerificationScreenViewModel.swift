//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SessionVerificationViewModelType = StateStoreViewModel<SessionVerificationScreenViewState, SessionVerificationScreenViewAction>

class SessionVerificationScreenViewModel: SessionVerificationViewModelType, SessionVerificationScreenViewModelProtocol {
    private let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
    private let flow: SessionVerificationScreenFlow
    
    private var stateMachine: SessionVerificationScreenStateMachine

    private var actionsSubject: PassthroughSubject<SessionVerificationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SessionVerificationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol,
         flow: SessionVerificationScreenFlow,
         verificationState: SessionVerificationScreenStateMachine.State = .initial) {
        self.sessionVerificationControllerProxy = sessionVerificationControllerProxy
        self.flow = flow
        
        stateMachine = SessionVerificationScreenStateMachine(state: verificationState)
        
        super.init(initialViewState: .init(flow: flow, verificationState: verificationState))
        
        setupStateMachine()
        
        sessionVerificationControllerProxy.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .receivedVerificationRequest:
                    break // Incoming verification requests are handled on the higher levels
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
        
        if case .responder(let details) = flow {
            Task {
                await self.sessionVerificationControllerProxy.acknowledgeVerificationRequest(details: details)
            }
        }
    }
    
    override func process(viewAction: SessionVerificationScreenViewAction) {
        switch viewAction {
        case .acceptVerificationRequest:
            stateMachine.processEvent(.acceptVerificationRequest)
        case .ignoreVerificationRequest:
            actionsSubject.send(.finished)
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
        case .done:
            actionsSubject.send(.finished)
        }
    }
    
    func stop() {
        switch stateMachine.state {
        case .initial, .verified, .cancelled: // non-cancellable states
            return
        default:
            stateMachine.processEvent(.cancel)
        }
    }
    
    // MARK: - Private
    
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
                
            state.verificationState = context.toState
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .acceptVerificationRequest, .acceptingVerificationRequest):
                acceptVerificationRequest()
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
            case (.initial, _, .cancelled):
                if case .responder = flow {
                    actionsSubject.send(.finished)
                }
            default:
                break
            }
        }
        
        stateMachine.addErrorHandler { context in
            MXLog.error("Failed transition with context: \(context)")
        }
    }
    
    private func acceptVerificationRequest() {
        Task {
            guard case .responder = flow else {
                fatalError("Incorrect API usage.")
            }
            
            switch await sessionVerificationControllerProxy.acceptVerificationRequest() {
            case .success:
                stateMachine.processEvent(.didAcceptVerificationRequest)
            case .failure:
                stateMachine.processEvent(.didFail)
            }
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
