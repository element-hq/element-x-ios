//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

nonisolated enum Target: String {
    case mainApp = "elementx"
    case nse
    case shareExtension = "shareextension"
    case tests
    
    var useLightweightTokioRuntime: Bool {
        switch self {
        case .mainApp: false
        case .nse: true
        case .shareExtension: true
        case .tests: false
        }
    }
    
    var logFilePrefix: String {
        switch self {
        case .mainApp:
            "console"
        default:
            rawValue
        }
    }
    
    /// Configures the target with logging and an appropriate runtime.
    ///
    /// Returns a `ConfigurationResult` which should be stored to
    ///   a) detect whether the platform is already configured.
    ///   b) automatically reconfigure the platform as necessary.
    func configure(logLevel: LogLevel,
                   traceLogPacks: Set<TraceLogPack>,
                   sentryURL: URL?,
                   keychainController: KeychainControllerProtocol,
                   appHooks: AppHooks) -> ConfigurationResult {
        let tracingConfiguration = Tracing.buildConfiguration(logLevel: logLevel,
                                                              traceLogPacks: traceLogPacks,
                                                              currentTarget: rawValue,
                                                              filePrefix: logFilePrefix,
                                                              sentryURL: sentryURL)
        
        do {
            try initPlatform(config: tracingConfiguration, useLightweightTokioRuntime: useLightweightTokioRuntime)
        } catch {
            fatalError("Failed configuring target \(self) with error: \(error)")
        }
        
        // Setup sentry above but disable it by default. It will be started
        // later together with the analytics service if the user consents.
        enableSentryLogging(enabled: false)
        
        MXLog.configure(currentTarget: rawValue)
        
        let context = Context(keychainController: keychainController)
        let hookCancellable = context.statePublisher
            .sink { context in
                appHooks.tracingHook.update(tracingConfiguration, for: context)
            }
        
        return ConfigurationResult(context: context, hookCancellable: hookCancellable)
    }
    
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
        
        /// Updates the context for a new authentication flow.
        func startAuthentication() {
            authenticationHomeserver = .undiscovered
        }
        
        /// Updates the context with the state of the authentication flow.
        func updateAuthentication(homeserver: String) {
            authenticationHomeserver = .discovered(homeserver)
        }
        
        /// Updates the context for a finished authentication flow.
        func finishAuthentication() {
            authenticationHomeserver = nil
        }
        
        nonisolated struct State: Equatable, Sendable {
            /// The homeserver of the authentication flow.
            nonisolated enum AuthenticationHomeserver: Equatable, Sendable {
                case undiscovered
                case discovered(String)
            }
            
            /// The homeservers of the sessions in the keychain.
            var sessionHomeservers: Set<String>
            /// The homeserver of the authentication flow, or `nil` when the flow isn't shown.
            var authenticationHomeserver: AuthenticationHomeserver?
        }
    }
    
    /// The result of calling ``configure(logLevel:traceLogPacks:sentryURL:keychainController:appHooks:)``.
    /// This must be stored - see the docs on the configure method to learn more.
    struct ConfigurationResult {
        let context: Context
        private let hookCancellable: AnyCancellable
        
        init(context: Context, hookCancellable: AnyCancellable) {
            self.context = context
            self.hookCancellable = hookCancellable
        }
    }
}
