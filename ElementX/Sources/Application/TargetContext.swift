//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension Target {
    /// The context that the target's configuration follows.
    final nonisolated class Context {
        private let keychainController: KeychainControllerProtocol
        private let stateSubject: CurrentValueSubject<State, Never>
        
        var statePublisher: CurrentValuePublisher<State, Never> {
            stateSubject.asCurrentValuePublisher()
        }
        
        private var authenticationHomeserver: State.AuthenticationHomeserver? {
            didSet { update() }
        }
        
        init(keychainController: KeychainControllerProtocol) {
            self.keychainController = keychainController
            // This runs before logging is configured, which collectSessionHomeservers() is safe for.
            stateSubject = .init(State(sessionHomeservers: keychainController.collectSessionHomeservers(), authenticationHomeserver: nil))
        }
        
        /// Reloads the context from storage, which should be called whenever an account is added or removed.
        func update() {
            stateSubject.send(State(sessionHomeservers: keychainController.collectSessionHomeservers(), authenticationHomeserver: authenticationHomeserver))
        }
        
        /// Marks the authentication flow as shown, before it has built a client.
        func startAuthentication() {
            authenticationHomeserver = .unknown
        }
        
        /// Sets the homeserver of the client that the authentication flow has built.
        func updateAuthentication(homeserver: String) {
            authenticationHomeserver = .known(homeserver)
        }
        
        /// Marks the authentication flow as no longer shown.
        func finishAuthentication() {
            authenticationHomeserver = nil
        }
    }
}

extension Target.Context {
    nonisolated struct State: Equatable, Sendable {
        /// The homeserver of the authentication flow.
        nonisolated enum AuthenticationHomeserver: Equatable, Sendable {
            /// The flow hasn't built a client yet.
            case unknown
            /// The flow has built a client for this homeserver.
            case known(String)
        }
        
        /// The homeservers of the sessions in the keychain.
        var sessionHomeservers: Set<String>
        /// The homeserver of the authentication flow, or `nil` when the flow isn't shown.
        var authenticationHomeserver: AuthenticationHomeserver?
    }
}
