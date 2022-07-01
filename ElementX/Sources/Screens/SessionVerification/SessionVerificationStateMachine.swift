//
//  SessionVerificationStateMachine.swift
//  ElementX
//
//  Created by Stefan Ceriu on 15/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftState

class SessionVerificationStateMachine {
    /// States the SessionVerificationViewModel can find itself in
    enum State: StateType {
        /// The initial state, before verification started
        case initial
        /// Waiting for verification acceptance
        case requestingVerification
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

    // swiftlint:disable cyclomatic_complexity
    init() {
        stateMachine = StateMachine(state: .initial) { machine in
            machine.addRoutes(event: .requestVerification, transitions: [ .initial => .requestingVerification ])
            machine.addRoutes(event: .didFail, transitions: [ .requestingVerification => .initial ])
            
            machine.addRoutes(event: .cancel, transitions: [ .requestingVerification => .cancelling ])
            machine.addRoutes(event: .didCancel, transitions: [ .requestingVerification => .cancelled ])
            
            // Cancellation request from the other party should either take us from `.cancelling`
            // to `.cancelled` or keep us in `.cancelled` if already there. There is more `.didCancel`
            // handling in `addRouteMapping` for states containing associated values
            machine.addRoutes(event: .didCancel, transitions: [ .cancelling => .cancelled ])
            machine.addRoutes(event: .didCancel, transitions: [ .cancelled => .cancelled ])
            machine.addRoutes(event: .didFail, transitions: [ .cancelled => .cancelled ])
            
            machine.addRoutes(event: .restart, transitions: [ .cancelled => .initial ])
            
            // Transitions with associated values need to be handled through `addRouteMapping`
            machine.addRouteMapping { event, fromState, _ in
                switch (event, fromState) {
                case (.didReceiveChallenge(let emojis), .requestingVerification):
                    return .showingChallenge(emojis: emojis)
                
                case (.acceptChallenge, .showingChallenge(let emojis)):
                    return .acceptingChallenge(emojis: emojis)
                case (.didFail, .acceptingChallenge(let emojis)):
                    return .showingChallenge(emojis: emojis)
                
                case (.didAcceptChallenge, .acceptingChallenge):
                    return .verified
                
                case (.declineChallenge, .showingChallenge(let emojis)):
                    return .decliningChallenge(emojis: emojis)
                case (.didFail, .decliningChallenge(let emojis)):
                    return .showingChallenge(emojis: emojis)
                
                case (.cancel, .showingChallenge):
                    return .cancelling
                case (.cancel, .acceptingChallenge):
                    return .cancelling
                case (.cancel, .decliningChallenge):
                    return .cancelling
                
                case (.didCancel, .showingChallenge):
                    return .cancelled
                case (.didCancel, .acceptingChallenge):
                    return .cancelled
                case (.didCancel, .decliningChallenge):
                    return .cancelled
                    
                default:
                    return nil
                }
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
    
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
