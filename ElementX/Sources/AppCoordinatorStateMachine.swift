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
    enum State: StateType {
        case initial
        case signedOut, signingOut
        case signedIn, signingIn
        case homeScreen
        case roomScreen(roomId: String)
    }

    enum Event: EventType {
        case start
        case attemptSignIn, succeededSigningIn, failedSigningIn
        case showHomeScreen
        case attemptSignOut, succeededSigningOut, failedSigningOut
        case showRoomScreen(roomId: String), popRoomScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    init() {
        stateMachine = StateMachine(state: .initial) { machine in
            machine.addRoutes(event: .start, transitions: [ .initial => .signedOut ])
            
            machine.addRoutes(event: .attemptSignIn, transitions: [ .signedOut => .signingIn ])
            
            machine.addRoutes(event: .succeededSigningIn, transitions: [ .signingIn => .signedIn ])
            machine.addRoutes(event: .failedSigningIn, transitions: [ .signingIn => .signedOut ])
            
            machine.addRoutes(event: .showHomeScreen, transitions: [ .signedIn => .homeScreen ])
            machine.addRoutes(event: .attemptSignOut, transitions: [ .signedIn => .signingOut ])
            
            machine.addRoutes(event: .attemptSignOut, transitions: [ .homeScreen => .signingOut ])
            
            machine.addRoutes(event: .succeededSigningOut, transitions: [ .signingOut => .signedOut ])
            machine.addRoutes(event: .failedSigningOut, transitions: [ .signingOut => .any ])
            
            machine.addRouteMapping { event, fromState, _ in
                switch (event, fromState) {
                case (.showRoomScreen(let roomId), .homeScreen):
                    return .roomScreen(roomId: roomId)
                case (.popRoomScreen, .roomScreen):
                    return .homeScreen
                default:
                    return nil
                }
            }
        }
    }
    
    func processEvent(_ event: Event) {
        stateMachine.tryEvent(event)
    }
    
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
}
