//
//  AppCoordinatorStateMachine.swift
//  ElementX
//
//  Created by Stefan Ceriu on 30/05/2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import SwiftState

class AppCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the AppCoordinator starts
        case initial
        /// Showing the login screen
        case signedOut
        /// Processing sign in request
        case signingIn
        /// Successfully signed in
        case signedIn
        /// Showing the home screen
        case homeScreen
        /// Showing a particular room's timeline
        /// - Parameter roomId: that room's identifier
        case roomScreen(roomId: String)
        /// Processing a sign out request
        case signingOut
    }

    /// Events that can be triggered on the AppCoordinator state machine
    enum Event: EventType {
        /// Start AppCoordinator flows, move from initial
        case start
        /// A sign in request has been started
        case attemptedSignIn
        /// Signing it succeeded
        case succeededSigningIn
        /// Signing in failed
        case failedSigningIn
        /// Request home screen presentation
        case showHomeScreen
        /// Request sign out
        case attemptSignOut
        /// Signing out succeeded
        case succeededSigningOut
        /// Signing out failed
        case failedSigningOut
        /// Request presentation for a particular room
        /// - Parameter roomId:the room identifier
        case showRoomScreen(roomId: String)
        /// The room screen has been dismissed
        case dismissedRoomScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    init() {
        stateMachine = StateMachine(state: .initial) { machine in
            machine.addRoutes(event: .start, transitions: [ .initial => .signedOut ])
            
            machine.addRoutes(event: .attemptedSignIn, transitions: [ .signedOut => .signingIn ])
            
            machine.addRoutes(event: .succeededSigningIn, transitions: [ .signingIn => .signedIn ])
            machine.addRoutes(event: .failedSigningIn, transitions: [ .signingIn => .signedOut ])
            
            machine.addRoutes(event: .showHomeScreen, transitions: [ .signedIn => .homeScreen ])
            
            machine.addRoutes(event: .attemptSignOut, transitions: [ .homeScreen => .signingOut ])
            
            machine.addRoutes(event: .succeededSigningOut, transitions: [ .signingOut => .signedOut ])
            machine.addRoutes(event: .failedSigningOut, transitions: [ .signingOut => .homeScreen ])
            
            // Transitions with associated values need to be handled through `addRouteMapping`
            machine.addRouteMapping { event, fromState, _ in
                switch (event, fromState) {
                case (.showRoomScreen(let roomId), .homeScreen):
                    return .roomScreen(roomId: roomId)
                case (.dismissedRoomScreen, .roomScreen):
                    return .homeScreen
                default:
                    return nil
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
