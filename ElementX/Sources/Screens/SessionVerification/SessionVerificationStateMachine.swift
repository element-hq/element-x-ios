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

import Foundation
import SwiftState

class SessionVerificationStateMachine {
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
        stateMachine = StateMachine(state: .initial) { machine in
            machine.addRoutes(event: .requestVerification, transitions: [.initial => .requestingVerification])
            machine.addRoutes(event: .didAcceptVerificationRequest, transitions: [.requestingVerification => .verificationRequestAccepted])
            machine.addRoutes(event: .startSasVerification, transitions: [.verificationRequestAccepted => .startingSasVerification])
            machine.addRoutes(event: .didFail, transitions: [.requestingVerification => .initial])
            machine.addRoutes(event: .restart, transitions: [.cancelled => .initial])
            
            // Transitions with associated values need to be handled through `addRouteMapping`
            machine.addRouteMapping { event, fromState, _ in
                switch (event, fromState) {
                case (.didStartSasVerification, _):
                    return .sasVerificationStarted
                    
                case (.didReceiveChallenge(let emojis), .sasVerificationStarted):
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
                
                case (.cancel, _):
                    return .cancelling
                case (.didCancel, _):
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
