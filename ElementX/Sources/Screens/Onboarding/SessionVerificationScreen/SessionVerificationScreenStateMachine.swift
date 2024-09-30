//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftState

class SessionVerificationScreenStateMachine {
    /// States the SessionVerificationViewModel can find itself in
    enum State: StateType {
        /// The initial state, before verification started
        case initial
        /// Waiting for verification acceptance
        case requestingVerification
        /// Verification request accepted. Waiting for start
        case verificationRequestAccepted
        /// Waiting for SaS verification start
        case startingSasVerification
        /// A SaS verification flow has been started
        case sasVerificationStarted
        /// Verification accepted and emojis received
        case showingChallenge(emojis: [SessionVerificationEmoji])
        /// Emojis match locally
        case acceptingChallenge(emojis: [SessionVerificationEmoji])
        /// Emojis do not match locally
        case decliningChallenge(emojis: [SessionVerificationEmoji])
        /// Verification successful
        case verified
        /// User requested verification cancellation
        case cancelling
        /// The verification has been cancelled, remotely or locally
        case cancelled
    }
    
    /// Events that can be triggered on the SessionVerification state machine
    enum Event: EventType {
        /// Request verification
        case requestVerification
        /// The current verification request has been accepted
        case didAcceptVerificationRequest
        /// Start a SaS verification flow
        case startSasVerification
        /// Started a SaS verification flow
        case didStartSasVerification
        /// Has received emojis
        case didReceiveChallenge(emojis: [SessionVerificationEmoji])
        /// Emojis match
        case acceptChallenge
        /// Emojis do not match
        case declineChallenge
        /// Remote accepted challenge
        case didAcceptChallenge
        /// Request cancellation
        case cancel
        /// Verification cancelled
        case didCancel
        /// Request failed
        case didFail
        /// Restart the verification flow
        case restart
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: State {
        stateMachine.state
    }

    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }
    
    private func configure() {
        stateMachine.addRoutes(event: .requestVerification, transitions: [.initial => .requestingVerification])
        stateMachine.addRoutes(event: .didAcceptVerificationRequest, transitions: [.requestingVerification => .verificationRequestAccepted])
        stateMachine.addRoutes(event: .startSasVerification, transitions: [.verificationRequestAccepted => .startingSasVerification])
        stateMachine.addRoutes(event: .didFail, transitions: [.requestingVerification => .initial])
        stateMachine.addRoutes(event: .restart, transitions: [.cancelled => .initial])
        
        // Transitions with associated values need to be handled through `addRouteMapping`
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (_, .didStartSasVerification):
                return .sasVerificationStarted
                
            case (.sasVerificationStarted, .didReceiveChallenge(let emojis)):
                return .showingChallenge(emojis: emojis)
            case (.showingChallenge(let emojis), .acceptChallenge):
                return .acceptingChallenge(emojis: emojis)
            case (.acceptingChallenge(let emojis), .didFail):
                return .showingChallenge(emojis: emojis)
                
            case (.acceptingChallenge, .didAcceptChallenge):
                return .verified
                
            case (.showingChallenge(let emojis), .declineChallenge):
                return .decliningChallenge(emojis: emojis)
            case (.decliningChallenge(let emojis), .didFail):
                return .showingChallenge(emojis: emojis)
                
            case (_, .cancel):
                return .cancelling
            case (_, .didCancel):
                return .cancelled
                
            default:
                return nil
            }
        }
        
        addTransitionHandler { context in
            if let event = context.event {
                MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                MXLog.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
    }
    
    /// Attempt to move the state machine to another state through an event
    /// It will either invoke the `transitionHandler` or the `errorHandler` depending on its current state
    func processEvent(_ event: Event) {
        stateMachine.tryEvent(event)
    }
    
    /// Registers a callback for processing state machine transitions
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    /// Registers a callback for processing state machine errors
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
}
