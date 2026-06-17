//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftState
import SwiftUI

@MainActor
protocol AuthenticationFlowCoordinatorDelegate: AnyObject {
    func authenticationFlowCoordinator(didLoginWithSession userSession: UserSessionProtocol)
}

class AuthenticationFlowCoordinator: FlowCoordinatorProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let bugReportService: BugReportServiceProtocol
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let identityServiceClient: IdentityServiceClientProtocol? // GUA FORK
    private let resolverClient: ResolverClientProtocol? // GUA FORK: phone -> homeserver routing
    private let usesPhoneLoginHint: Bool // GUA FORK
    
    enum State: StateType {
        /// The state machine hasn't started.
        case initial
        
        // GUA FORK BEGIN: Gua phone-OTP-PIN onboarding states
        /// The Gua phone-number entry screen (default entry point for normal users).
        case phoneEntryScreen
        /// The Gua OTP entry screen.
        case otpEntryScreen
        /// Two-step verification PIN challenge shown to returning users who set a PIN.
        case pinChallengeScreen
        /// Profile setup screen shown to new users after a successful OTP verify.
        case profileSetupScreen
        /// Optional PIN setup step offered to brand-new users after profile setup.
        case pinSetupScreen
        // GUA FORK END
        
        /// The initial screen shown when you first launch the app.
        case startScreen
        
        /// The screen used for the whole QR Code flow.
        case qrCodeLoginScreen
        
        /// The screen to continue authentication with the current server.
        case serverConfirmationScreen
        /// The screen to choose a different server.
        case serverSelectionScreen
        /// The web authentication session is being presented.
        case oidcAuthentication
        /// The screen to login with a password.
        case loginScreen
        
        /// The screen to report an error.
        case bugReportFlow
        
        /// The flow is complete.
        case complete
    }
    
    enum Event: EventType {
        /// The legacy flow is being started.
        case start
        /// Modify the flow using the provisioning parameters in the `userInfo`.
        case applyProvisioningParameters
        // GUA FORK BEGIN: Gua phone-OTP-PIN events
        /// The Gua phone-OTP flow is being started.
        case startPhoneAuth
        /// The user submitted a phone number (carried via `userInfo`).
        case continueWithPhone
        /// The user dropped into the legacy auth flow from the phone screen.
        case useLegacyAuth
        /// The user cancelled OTP entry to edit their phone number.
        case cancelledOTPEntry
        /// OTP verified for a returning user with two-step verification — prompt for PIN.
        case needsPinChallenge
        /// The user backed out of the PIN challenge (returns to OTP entry).
        case cancelledPinChallenge
        /// OTP verified for a brand-new phone — advance to profile setup.
        case needsProfileSetup
        /// The user backed out of profile setup (returns to OTP entry).
        case cancelledProfileSetup
        /// Profile setup completed; offer to create a PIN before finishing sign-in.
        case offerPinSetup
        /// Backend rejected the chosen username during signup completion.
        case usernameTakenDuringSignup
        // GUA FORK END
        
        /// The user would like to login with a QR code.
        case loginWithQR
        /// Show the server confirmation screen.
        case confirmServer(AuthenticationFlow)
        /// The user encountered a problem.
        case reportProblem
        
        /// The QR login flow was aborted.
        case cancelledLoginWithQR
        /// The user aborted manual login.
        case cancelledServerConfirmation
        
        /// The user would like to enter a different server.
        case changeServer(AuthenticationFlow)
        /// The user is no longer selecting a server.
        case dismissedServerSelection
        
        /// Show the web authentication session for OIDC (using the parameters in the `userInfo`).
        case continueWithOIDC
        /// The web authentication session was aborted.
        case cancelledOIDCAuthentication(previousState: State)
        /// Show the screen to login with password (with the optional login hint in the `userInfo`).
        case continueWithPassword
        /// The password login was aborted.
        case cancelledPasswordLogin(previousState: State)
        
        /// The user has finished reporting a problem (or viewing the logs).
        case bugReportFlowComplete
        
        /// The user has successfully signed in. The new session can be found in the `userInfo`.
        case signedIn
    }
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private var oidcPresenter: OIDCAuthenticationPresenter?
    
    // periphery:ignore - retaining purpose
    private var bugReportFlowCoordinator: BugReportFlowCoordinator?
    // periphery:ignore - retaining purpose
    private var phoneEntryScreenCoordinator: PhoneEntryScreenCoordinator?
    // periphery:ignore - retaining purpose
    private var otpEntryScreenCoordinator: OtpEntryScreenCoordinator?
    // periphery:ignore - retaining purpose
    private var pinChallengeScreenCoordinator: PinChallengeScreenCoordinator?
    // periphery:ignore - retaining purpose
    private var profileSetupScreenCoordinator: ProfileSetupScreenCoordinator?
    // periphery:ignore - retaining purpose
    private var pinSetupScreenCoordinator: PinSetupScreenCoordinator?
    private var isHandlingPhoneSubmission = false
    private var isHandlingOTPVerification = false
    private var isHandlingProfileSubmission = false
    private var isHandlingPinVerification = false
    private var isHandlingPinSetup = false
    
    weak var delegate: AuthenticationFlowCoordinatorDelegate?
    
    init(authenticationService: AuthenticationServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         navigationRootCoordinator: NavigationRootCoordinator,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         identityServiceClient: IdentityServiceClientProtocol? = nil,
         resolverClient: ResolverClientProtocol? = nil,
         usesPhoneLoginHint: Bool = false) {
        self.authenticationService = authenticationService
        self.bugReportService = bugReportService
        self.navigationRootCoordinator = navigationRootCoordinator
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.identityServiceClient = identityServiceClient
        self.resolverClient = resolverClient
        self.usesPhoneLoginHint = usesPhoneLoginHint
        
        navigationStackCoordinator = NavigationStackCoordinator()
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start() {
        if usesPhoneLoginHint, !appSettings.legacyAuthEnabled {
            stateMachine.tryEvent(.startPhoneAuth)
        } else {
            stateMachine.tryEvent(.start)
        }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        switch appRoute {
        case .accountProvisioningLink(let provisioningParameters):
            guard appSettings.allowOtherAccountProviders else {
                MXLog.error("Provisioning links not allowed, ignoring.")
                return
            }
            
            if stateMachine.state != .startScreen {
                clearRoute(animated: animated)
            }
            
            stateMachine.tryEvent(.applyProvisioningParameters, userInfo: provisioningParameters)
        default:
            fatalError()
        }
    }
    
    func clearRoute(animated: Bool) {
        switch stateMachine.state {
        case .initial, .startScreen, .phoneEntryScreen:
            break
        case .otpEntryScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
            stateMachine.tryEvent(.cancelledOTPEntry)
        case .pinChallengeScreen:
            navigationStackCoordinator.pop(animated: animated)
            stateMachine.tryEvent(.cancelledPinChallenge)
        case .profileSetupScreen:
            navigationStackCoordinator.pop(animated: animated)
            stateMachine.tryEvent(.cancelledProfileSetup)
        case .pinSetupScreen:
            // PIN setup is optional and presented after the user has already committed to a username —
            // dismissals are handled by an explicit "Not now" button in the screen itself.
            break
        case .qrCodeLoginScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            stateMachine.tryEvent(.cancelledLoginWithQR) // Needs to be handled manually.
        case .serverConfirmationScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .serverSelectionScreen:
            navigationStackCoordinator.setSheetCoordinator(nil)
            navigationStackCoordinator.popToRoot(animated: animated)
        case .oidcAuthentication:
            oidcPresenter?.cancel()
            navigationStackCoordinator.popToRoot(animated: animated)
        case .loginScreen:
            navigationStackCoordinator.popToRoot(animated: animated)
        case .bugReportFlow:
            navigationStackCoordinator.setSheetCoordinator(nil)
        case .complete:
            fatalError()
        }
    }
    
    // MARK: - Setup
    
    private func configureStateMachine() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .startScreen]) { [weak self] _ in
            self?.showStartScreen(fromState: .initial)
        }
        
        // Gua phone-OTP flow
        
        stateMachine.addRoutes(event: .startPhoneAuth, transitions: [.initial => .phoneEntryScreen]) { [weak self] _ in
            self?.showPhoneEntryScreen(fromState: .initial)
        }
        stateMachine.addRoutes(event: .continueWithPhone, transitions: [.phoneEntryScreen => .otpEntryScreen]) { [weak self] context in
            guard let phoneNumber = context.userInfo as? String else { fatalError("Missing phone number for OTP entry.") }
            self?.showOTPEntryScreen(phoneNumber: phoneNumber)
        }
        stateMachine.addRoutes(event: .cancelledOTPEntry, transitions: [.otpEntryScreen => .phoneEntryScreen])
        stateMachine.addRoutes(event: .needsPinChallenge, transitions: [.otpEntryScreen => .pinChallengeScreen]) { [weak self] context in
            guard let challengeContext = context.userInfo as? PinChallengeContext else { fatalError("Missing PIN challenge context.") }
            self?.showPinChallengeScreen(challengeContext: challengeContext)
        }
        stateMachine.addRoutes(event: .cancelledPinChallenge, transitions: [.pinChallengeScreen => .otpEntryScreen])
        stateMachine.addRoutes(event: .needsProfileSetup, transitions: [.otpEntryScreen => .profileSetupScreen]) { [weak self] context in
            guard let setupContext = context.userInfo as? ProfileSetupContext else { fatalError("Missing profile setup context.") }
            self?.showProfileSetupScreen(setupContext: setupContext)
        }
        stateMachine.addRoutes(event: .cancelledProfileSetup, transitions: [.profileSetupScreen => .otpEntryScreen,
                                                                            .pinSetupScreen => .phoneEntryScreen])
        stateMachine.addRoutes(event: .offerPinSetup, transitions: [.profileSetupScreen => .pinSetupScreen]) { [weak self] context in
            guard let pending = context.userInfo as? PendingSignupContext else { fatalError("Missing pending signup context for PIN setup.") }
            self?.showPinSetupScreen(pendingSignup: pending)
        }
        // Username taken at the very end of signup: pop the PIN setup screen and surface the error
        // inline on the still-mounted ProfileSetup screen. The signup token survives because the
        // backend only consumes it on success.
        stateMachine.addRoutes(event: .usernameTakenDuringSignup, transitions: [.pinSetupScreen => .profileSetupScreen]) { [weak self] _ in
            self?.navigationStackCoordinator.pop(animated: true)
            self?.profileSetupScreenCoordinator?.displayError(IdentityServiceError.usernameTaken.localizedDescription)
        }
        stateMachine.addRoutes(event: .useLegacyAuth, transitions: [.phoneEntryScreen => .startScreen]) { [weak self] _ in
            self?.showStartScreen(fromState: .phoneEntryScreen)
        }
        
        stateMachine.addRoutes(event: .applyProvisioningParameters, transitions: [.initial => .startScreen,
                                                                                  .startScreen => .startScreen]) { [weak self] context in
            guard let provisioningParameters = context.userInfo as? AccountProvisioningParameters else { fatalError("The authentication configuration is missing.") }
            self?.showStartScreen(fromState: context.fromState, applying: provisioningParameters)
        }
        
        // QR Code
        
        stateMachine.addRoutes(event: .loginWithQR, transitions: [.startScreen => .qrCodeLoginScreen]) { [weak self] _ in
            self?.showQRCodeLoginScreen()
        }
        stateMachine.addRoutes(event: .cancelledLoginWithQR, transitions: [.qrCodeLoginScreen => .startScreen])
        
        // Manual Authentication
        
        stateMachine.addRoutes(event: .confirmServer(.login), transitions: [.startScreen => .serverConfirmationScreen]) { [weak self] _ in
            self?.showServerConfirmationScreen(authenticationFlow: .login)
        }
        stateMachine.addRoutes(event: .confirmServer(.register), transitions: [.startScreen => .serverConfirmationScreen]) { [weak self] _ in
            self?.showServerConfirmationScreen(authenticationFlow: .register)
        }
        stateMachine.addRoutes(event: .cancelledServerConfirmation, transitions: [.serverConfirmationScreen => .startScreen])
        
        stateMachine.addRoutes(event: .changeServer(.login), transitions: [.serverConfirmationScreen => .serverSelectionScreen]) { [weak self] _ in
            self?.showServerSelectionScreen(authenticationFlow: .login)
        }
        stateMachine.addRoutes(event: .changeServer(.register), transitions: [.serverConfirmationScreen => .serverSelectionScreen]) { [weak self] _ in
            self?.showServerSelectionScreen(authenticationFlow: .register)
        }
        stateMachine.addRoutes(event: .dismissedServerSelection, transitions: [.serverSelectionScreen => .serverConfirmationScreen])
        
        stateMachine.addRoutes(event: .continueWithOIDC, transitions: [.phoneEntryScreen => .oidcAuthentication,
                                                                       .serverConfirmationScreen => .oidcAuthentication,
                                                                       .startScreen => .oidcAuthentication]) { [weak self] context in
            guard let (oidcData, window) = context.userInfo as? (OIDCAuthorizationDataProxy, UIWindow) else {
                fatalError("Missing the OIDC data and presentation anchor.")
            }
            self?.showOIDCAuthentication(oidcData: oidcData, presentationAnchor: window, fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledOIDCAuthentication(previousState: .phoneEntryScreen), transitions: [.oidcAuthentication => .phoneEntryScreen])
        stateMachine.addRoutes(event: .cancelledOIDCAuthentication(previousState: .serverConfirmationScreen), transitions: [.oidcAuthentication => .serverConfirmationScreen])
        stateMachine.addRoutes(event: .cancelledOIDCAuthentication(previousState: .startScreen), transitions: [.oidcAuthentication => .startScreen])
        
        stateMachine.addRoutes(event: .continueWithPassword, transitions: [.serverConfirmationScreen => .loginScreen,
                                                                           .startScreen => .loginScreen]) { [weak self] context in
            let loginHint = context.userInfo as? String
            self?.showLoginScreen(loginHint: loginHint, fromState: context.fromState)
        }
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .serverConfirmationScreen), transitions: [.loginScreen => .serverConfirmationScreen])
        stateMachine.addRoutes(event: .cancelledPasswordLogin(previousState: .startScreen), transitions: [.loginScreen => .startScreen])
        
        // Bug Report
        
        stateMachine.addRoutes(event: .reportProblem, transitions: [.startScreen => .bugReportFlow]) { [weak self] _ in
            self?.startBugReportFlow()
        }
        stateMachine.addRoutes(event: .bugReportFlowComplete, transitions: [.bugReportFlow => .startScreen])
        
        // Completion
        
        stateMachine.addRoutes(event: .signedIn, transitions: [.qrCodeLoginScreen => .complete,
                                                               .oidcAuthentication => .complete,
                                                               .loginScreen => .complete,
                                                               .otpEntryScreen => .complete,
                                                               .pinChallengeScreen => .complete,
                                                               .profileSetupScreen => .complete,
                                                               .pinSetupScreen => .complete]) { [weak self] context in
            guard let userSession = context.userInfo as? UserSessionProtocol else { fatalError("The user session wasn't included in the context") }
            self?.userHasSignedIn(userSession: userSession)
        }
        
        // Logging
        
        stateMachine.addAnyHandler(.any => .any) { context in
            MXLog.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(String(describing: context.event))`.")
        }
        
        // Unhandled
        
        stateMachine.addErrorHandler { context in
            switch (context.fromState, context.toState) {
            case (.complete, .complete):
                break // Ignore all events triggered by
            default:
                fatalError("Unexpected transition: \(context)")
            }
        }
    }
    
    private func showStartScreen(fromState: State, applying provisioningParameters: AccountProvisioningParameters? = nil) {
        let parameters = AuthenticationStartScreenParameters(authenticationService: authenticationService,
                                                             provisioningParameters: provisioningParameters,
                                                             isBugReportServiceEnabled: bugReportService.isEnabled,
                                                             appSettings: appSettings,
                                                             userIndicatorController: userIndicatorController)
        let coordinator = AuthenticationStartScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .loginWithQR:
                    stateMachine.tryEvent(.loginWithQR)
                case .login:
                    stateMachine.tryEvent(.confirmServer(.login))
                case .register:
                    stateMachine.tryEvent(.confirmServer(.register))
                case .reportProblem:
                    stateMachine.tryEvent(.reportProblem)
                    
                case .loginDirectlyWithOIDC(let oidcData, let window):
                    stateMachine.tryEvent(.continueWithOIDC, userInfo: (oidcData, window))
                case .loginDirectlyWithPassword(let loginHint):
                    stateMachine.tryEvent(.continueWithPassword, userInfo: loginHint)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        if fromState == .initial {
            navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
        }
    }
    
    // MARK: - Gua Phone-OTP
    
    private func showPhoneEntryScreen(fromState: State) {
        let coordinator = PhoneEntryScreenCoordinator(parameters: .init(isLegacyAuthEnabled: appSettings.legacyAuthEnabled))
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .continue(let phoneNumber):
                    handlePhoneSubmission(phoneNumber: phoneNumber, coordinator: coordinator)
                case .useLegacyAuth:
                    stateMachine.tryEvent(.useLegacyAuth)
                }
            }
            .store(in: &cancellables)
        
        coordinator.start()
        phoneEntryScreenCoordinator = coordinator
        otpEntryScreenCoordinator = nil
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        if fromState == .initial {
            navigationRootCoordinator.setRootCoordinator(navigationStackCoordinator)
        }
    }
    
    private func handlePhoneSubmission(phoneNumber: String, coordinator: PhoneEntryScreenCoordinator) {
        guard !isHandlingPhoneSubmission else { return }
        isHandlingPhoneSubmission = true
        coordinator.setSubmitting(true)
        Task { [weak self] in
            guard let self else { return }
            defer {
                coordinator.setSubmitting(false)
                self.isHandlingPhoneSubmission = false
            }
            
            // GUA FORK: ask the resolver which homeserver this phone belongs to (login) or should be
            // created on (register), instead of hardcoding a single account provider. Falls back to the
            // configured default provider when the resolver is unavailable or not configured, so the app
            // keeps working before the resolver is deployed.
            // Use the homeserver base URL the resolver returned directly (configure(for:) accepts a
            // server name OR a homeserver URL). This avoids re-discovering via HTTPS well-known on the
            // server name, which is redundant and fails for http/localhost homeservers.
            let resolution = await resolveHomeserver(forPhone: phoneNumber)
            guard let accountProvider = resolution?.homeserver.baseURL ?? appSettings.accountProviders.first else {
                coordinator.displayError(L10n.errorUnknown)
                return
            }
            let flow: AuthenticationFlow = (resolution?.exists == false) ? .register : .login

            switch await authenticationService.configure(for: accountProvider, flow: flow) {
            case .success:
                break
            case .failure(let error):
                MXLog.error("Failed configuring OIDC login from phone hint: \(error)")
                coordinator.displayError(error.localizedDescription)
                return
            }
            
            guard authenticationService.homeserver.value.loginMode.supportsOIDCFlow else {
                coordinator.displayError(L10n.screenLoginErrorUnsupportedAuthentication)
                return
            }
            
            guard let window = appMediator.windowManager.mainWindow else {
                coordinator.displayError(L10n.errorUnknown)
                return
            }
            
            switch await authenticationService.urlForOIDCLogin(loginHint: phoneNumber) {
            case .success(let oidcData):
                stateMachine.tryEvent(.continueWithOIDC, userInfo: (oidcData, window))
            case .failure(let error):
                MXLog.error("Failed creating OIDC login URL from phone hint: \(error)")
                coordinator.displayError(error.localizedDescription)
            }
        }
    }
    
    /// GUA FORK: resolve a phone to its homeserver via the Gua resolver. Returns `nil` (so the caller falls
    /// back to the default account provider) when the resolver isn't configured or the lookup fails.
    private func resolveHomeserver(forPhone phoneNumber: String) async -> HomeserverResolution? {
        guard let resolverClient else { return nil }
        do {
            return try await resolverClient.resolve(phoneNumber: phoneNumber)
        } catch {
            MXLog.warning("Resolver lookup failed; falling back to the default account provider: \(error)")
            return nil
        }
    }

    private func showOTPEntryScreen(phoneNumber: String) {
        let coordinator = OtpEntryScreenCoordinator(parameters: .init(phoneNumber: phoneNumber))
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .verify(let code):
                    handleOTPVerification(phoneNumber: phoneNumber, code: code, coordinator: coordinator)
                case .resend:
                    handleOTPResend(phoneNumber: phoneNumber, coordinator: coordinator)
                case .changePhone:
                    // Fire the state machine event FIRST, then pop. SwiftUI's onDismiss callback
                    // runs synchronously during pop and would otherwise transition the state
                    // before this explicit tryEvent ran, leaving us with a duplicate from-state.
                    stateMachine.tryEvent(.cancelledOTPEntry)
                    navigationStackCoordinator.pop(animated: true)
                }
            }
            .store(in: &cancellables)
        
        coordinator.start()
        otpEntryScreenCoordinator = coordinator
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            // The SwiftUI nav stack fires this on programmatic `pop`/`popToRoot` as well as user gestures.
            // Only emit the cancel event if the state machine is still on this screen; otherwise the
            // parent flow already transitioned away and the event would be unrouted.
            guard self?.stateMachine.state == .otpEntryScreen else { return }
            self?.stateMachine.tryEvent(.cancelledOTPEntry)
        }
    }
    
    private func handleOTPVerification(phoneNumber: String, code: String, coordinator: OtpEntryScreenCoordinator) {
        guard !isHandlingOTPVerification else { return }
        guard let client = identityServiceClient else {
            coordinator.displayError("Identity service is not configured.")
            return
        }
        isHandlingOTPVerification = true
        coordinator.setVerifying(true)
        Task { [weak self] in
            do {
                let outcome = try await client.verifyOTP(phone: phoneNumber,
                                                         code: code,
                                                         pin: nil,
                                                         device: .current)
                switch outcome {
                case .newUser(let signupToken):
                    self?.isHandlingOTPVerification = false
                    coordinator.setVerifying(false)
                    self?.stateMachine.tryEvent(.needsProfileSetup,
                                                userInfo: ProfileSetupContext(phoneNumber: phoneNumber, signupToken: signupToken))
                case .pinRequired(let challengeToken):
                    self?.isHandlingOTPVerification = false
                    coordinator.setVerifying(false)
                    self?.stateMachine.tryEvent(.needsPinChallenge,
                                                userInfo: PinChallengeContext(phoneNumber: phoneNumber, challengeToken: challengeToken))
                case .existingUser(let session):
                    let result = await self?.authenticationService.loginWithExistingMatrixSession(accessToken: session.accessToken,
                                                                                                  refreshToken: nil,
                                                                                                  userId: session.userId,
                                                                                                  deviceId: session.deviceId,
                                                                                                  homeserverUrl: session.baseUrl)
                    switch result {
                    case .success(let userSession):
                        self?.appSettings.hasRunIdentityConfirmationOnboarding = true
                        self?.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                    case .failure(let error):
                        coordinator.setVerifying(false)
                        self?.isHandlingOTPVerification = false
                        MXLog.error("Matrix session restoration failed after OTP verify: \(error)")
                        coordinator.displayError("Could not start your Matrix session. Please try again.")
                    case .none:
                        coordinator.setVerifying(false)
                        self?.isHandlingOTPVerification = false
                    }
                }
            } catch let error as IdentityServiceError {
                coordinator.setVerifying(false)
                self?.isHandlingOTPVerification = false
                coordinator.displayError(error.localizedDescription)
            } catch {
                coordinator.setVerifying(false)
                self?.isHandlingOTPVerification = false
                MXLog.error("OTP verification failed: \(error)")
                coordinator.displayError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Profile Setup (new user signup)
    
    private struct ProfileSetupContext {
        let phoneNumber: String
        let signupToken: String
    }
    
    private struct PinChallengeContext {
        let phoneNumber: String
        let challengeToken: String
    }
    
    private struct PendingSignupContext {
        let signupToken: String
        let phoneNumber: String
        let username: String
        let displayName: String
    }
    
    private func showProfileSetupScreen(setupContext: ProfileSetupContext) {
        let coordinator = ProfileSetupScreenCoordinator(parameters: .init(phoneNumber: setupContext.phoneNumber))

        // Real-time username availability so the user finds out before reaching the PIN screen.
        if let client = identityServiceClient {
            coordinator.setUsernameAvailabilityChecker { username in
                try await client.checkUsernameAvailability(username)
            }
        }
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .complete(let username, let displayName):
                    // Only fire the transition if we're still on the profile screen \u2014 SwiftUI/Compound
                    // button presses can occasionally re-emit, and `offerPinSetup` has no route from
                    // `.pinSetupScreen` so a duplicate would crash the state machine's error handler.
                    guard stateMachine.state == .profileSetupScreen else { return }
                    // Move to optional PIN setup; we'll call completeSignup once the user either
                    // sets a PIN or explicitly skips, so the signup token is consumed exactly once.
                    let pending = PendingSignupContext(signupToken: setupContext.signupToken,
                                                       phoneNumber: setupContext.phoneNumber,
                                                       username: username,
                                                       displayName: displayName)
                    stateMachine.tryEvent(.offerPinSetup, userInfo: pending)
                case .cancel:
                    stateMachine.tryEvent(.cancelledProfileSetup)
                    navigationStackCoordinator.pop(animated: true)
                }
            }
            .store(in: &cancellables)
        
        coordinator.start()
        profileSetupScreenCoordinator = coordinator
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            guard self?.stateMachine.state == .profileSetupScreen else { return }
            self?.stateMachine.tryEvent(.cancelledProfileSetup)
        }
    }
    
    private func showPinSetupScreen(pendingSignup: PendingSignupContext) {
        let coordinator = PinSetupScreenCoordinator()
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .complete(let pin):
                    handleSignupCompletion(pendingSignup: pendingSignup, pin: pin, coordinator: coordinator)
                case .skip:
                    handleSignupCompletion(pendingSignup: pendingSignup, pin: nil, coordinator: coordinator)
                }
            }
            .store(in: &cancellables)
        
        coordinator.start()
        pinSetupScreenCoordinator = coordinator
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func handleSignupCompletion(pendingSignup: PendingSignupContext,
                                        pin: String?,
                                        coordinator: PinSetupScreenCoordinator) {
        guard !isHandlingProfileSubmission else { return }
        guard let client = identityServiceClient else {
            coordinator.displayError("Identity service is not configured.")
            return
        }
        isHandlingProfileSubmission = true
        coordinator.setSubmitting(true)
        Task { [weak self] in
            do {
                let session = try await client.completeSignup(signupToken: pendingSignup.signupToken,
                                                              username: pendingSignup.username,
                                                              displayName: pendingSignup.displayName,
                                                              pin: pin,
                                                              device: .current)
                let result = await self?.authenticationService.loginWithExistingMatrixSession(accessToken: session.accessToken,
                                                                                              refreshToken: nil,
                                                                                              userId: session.userId,
                                                                                              deviceId: session.deviceId,
                                                                                              homeserverUrl: session.baseUrl)
                switch result {
                case .success(let userSession):
                    self?.appSettings.hasRunIdentityConfirmationOnboarding = true
                    self?.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                case .failure(let error):
                    self?.isHandlingProfileSubmission = false
                    MXLog.error("Matrix session restoration failed after signup: \(error)")
                    coordinator.displayError("Could not start your Matrix session. Please try again.")
                case .none:
                    self?.isHandlingProfileSubmission = false
                }
            } catch let error as IdentityServiceError {
                self?.isHandlingProfileSubmission = false
                switch error {
                case .usernameTaken:
                    // Recoverable: return to ProfileSetup with the same signup token (backend
                    // doesn't consume it on failure) so the user can pick a different username.
                    self?.stateMachine.tryEvent(.usernameTakenDuringSignup)
                case .invalidSignupToken, .phoneAlreadyLinked:
                    // The signup session is dead — user has to redo OTP.
                    self?.userIndicatorController.submitIndicator(.init(title: error.localizedDescription))
                    self?.stateMachine.tryEvent(.cancelledProfileSetup)
                    self?.navigationStackCoordinator.popToRoot(animated: true)
                default:
                    coordinator.displayError(error.localizedDescription)
                }
            } catch {
                self?.isHandlingProfileSubmission = false
                MXLog.error("Signup completion failed: \(error)")
                coordinator.displayError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - PIN Challenge (returning user with two-step verification)
    
    private func showPinChallengeScreen(challengeContext: PinChallengeContext) {
        let coordinator = PinChallengeScreenCoordinator(parameters: .init(phoneNumber: challengeContext.phoneNumber))
        
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .verify(let pin):
                    handlePinVerification(challengeContext: challengeContext, pin: pin, coordinator: coordinator)
                case .forgotPin:
                    coordinator.displayError("PIN recovery isn't available yet. Try again or use another device that's already signed in.")
                case .cancel:
                    stateMachine.tryEvent(.cancelledPinChallenge)
                    navigationStackCoordinator.pop(animated: true)
                }
            }
            .store(in: &cancellables)
        
        coordinator.start()
        pinChallengeScreenCoordinator = coordinator
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            guard self?.stateMachine.state == .pinChallengeScreen else { return }
            self?.stateMachine.tryEvent(.cancelledPinChallenge)
        }
    }
    
    private func handlePinVerification(challengeContext: PinChallengeContext,
                                       pin: String,
                                       coordinator: PinChallengeScreenCoordinator) {
        guard !isHandlingPinVerification else { return }
        guard let client = identityServiceClient else {
            coordinator.displayError("Identity service is not configured.")
            return
        }
        isHandlingPinVerification = true
        coordinator.setVerifying(true)
        Task { [weak self] in
            do {
                let session = try await client.verifyPinChallenge(pinChallengeToken: challengeContext.challengeToken,
                                                                  pin: pin,
                                                                  device: .current)
                let result = await self?.authenticationService.loginWithExistingMatrixSession(accessToken: session.accessToken,
                                                                                              refreshToken: nil,
                                                                                              userId: session.userId,
                                                                                              deviceId: session.deviceId,
                                                                                              homeserverUrl: session.baseUrl)
                switch result {
                case .success(let userSession):
                    self?.appSettings.hasRunIdentityConfirmationOnboarding = true
                    self?.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                case .failure(let error):
                    coordinator.setVerifying(false)
                    self?.isHandlingPinVerification = false
                    MXLog.error("Matrix session restoration failed after PIN verify: \(error)")
                    coordinator.displayError("Could not start your Matrix session. Please try again.")
                case .none:
                    coordinator.setVerifying(false)
                    self?.isHandlingPinVerification = false
                }
            } catch let error as IdentityServiceError {
                coordinator.setVerifying(false)
                self?.isHandlingPinVerification = false
                // If the short-lived challenge expired, force the user back to OTP entry
                // (the OTP itself is still valid until they request a fresh one).
                if case .pinChallengeExpired = error {
                    self?.userIndicatorController.submitIndicator(.init(title: error.localizedDescription))
                    self?.stateMachine.tryEvent(.cancelledPinChallenge)
                    self?.navigationStackCoordinator.pop(animated: true)
                } else {
                    coordinator.displayError(error.localizedDescription)
                }
            } catch {
                coordinator.setVerifying(false)
                self?.isHandlingPinVerification = false
                MXLog.error("PIN verification failed: \(error)")
                coordinator.displayError(error.localizedDescription)
            }
        }
    }
    
    private func handleOTPResend(phoneNumber: String, coordinator: OtpEntryScreenCoordinator) {
        guard let client = identityServiceClient else {
            coordinator.displayError("Identity service is not configured.")
            return
        }
        Task {
            do {
                try await client.sendOTP(phone: phoneNumber, language: Locale.current.identifier)
                coordinator.resetForResend()
            } catch let error as IdentityServiceError {
                coordinator.displayError(error.localizedDescription)
            } catch {
                MXLog.error("Failed to resend OTP: \(error)")
                coordinator.displayError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - QR Code
    
    private func showQRCodeLoginScreen() {
        let coordinator = QRCodeLoginScreenCoordinator(parameters: .init(qrCodeLoginService: authenticationService,
                                                                         canSignInManually: appSettings.allowOtherAccountProviders, // No need to worry about provisioning links as we hide QR login.
                                                                         orientationManager: appMediator.windowManager,
                                                                         appMediator: appMediator))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .signInManually:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR)
                stateMachine.tryEvent(.confirmServer(.login))
            case .cancel:
                navigationStackCoordinator.setSheetCoordinator(nil)
                stateMachine.tryEvent(.cancelledLoginWithQR)
            case .done(let userSession):
                navigationStackCoordinator.setSheetCoordinator(nil)
                // Since the qr code login flow includes verification
                appSettings.hasRunIdentityConfirmationOnboarding = true
                DispatchQueue.main.async {
                    self.stateMachine.tryEvent(.signedIn, userInfo: userSession)
                }
            }
        }
        .store(in: &cancellables)
        navigationStackCoordinator.setSheetCoordinator(coordinator) // Don't use the callback (interactive dismiss disabled), choose the event with the action.
    }
    
    // MARK: - Manual Authentication
    
    private func showServerConfirmationScreen(authenticationFlow: AuthenticationFlow) {
        // Reset the service back to the default homeserver before continuing. This ensures
        // we check that registration is supported if it was previously configured for login.
        authenticationService.reset()
        
        let parameters = ServerConfirmationScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                       authenticationFlow: authenticationFlow,
                                                                       appSettings: appSettings,
                                                                       userIndicatorController: userIndicatorController)
        let coordinator = ServerConfirmationScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .continueWithOIDC(let oidcData, let window):
                stateMachine.tryEvent(.continueWithOIDC, userInfo: (oidcData, window))
            case .continueWithPassword:
                stateMachine.tryEvent(.continueWithPassword)
            case .changeServer:
                stateMachine.tryEvent(.changeServer(authenticationFlow))
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.cancelledServerConfirmation)
        }
    }
    
    private func showServerSelectionScreen(authenticationFlow: AuthenticationFlow) {
        let navigationCoordinator = NavigationStackCoordinator()
        
        let parameters = ServerSelectionScreenCoordinatorParameters(authenticationService: authenticationService,
                                                                    authenticationFlow: authenticationFlow,
                                                                    appSettings: appSettings,
                                                                    userIndicatorController: userIndicatorController)
        let coordinator = ServerSelectionScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .updated:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                case .dismiss:
                    navigationStackCoordinator.setSheetCoordinator(nil)
                }
            }
            .store(in: &cancellables)
        
        navigationCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(navigationCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedServerSelection)
        }
    }
    
    private func showOIDCAuthentication(oidcData: OIDCAuthorizationDataProxy, presentationAnchor: UIWindow, fromState: State) {
        let presenter = OIDCAuthenticationPresenter(authenticationService: authenticationService,
                                                    oidcRedirectURL: appSettings.oidcRedirectURL,
                                                    presentationAnchor: presentationAnchor,
                                                    userIndicatorController: userIndicatorController)
        oidcPresenter = presenter
        
        Task {
            switch await presenter.authenticate(using: oidcData) {
            case .success(let userSession):
                stateMachine.tryEvent(.signedIn, userInfo: userSession)
            case .failure:
                stateMachine.tryEvent(.cancelledOIDCAuthentication(previousState: fromState))
                // Nothing more to do, the alerts are handled by the presenter.
            }
            oidcPresenter = nil
        }
    }
    
    private func showLoginScreen(loginHint: String?, fromState: State) {
        let parameters = LoginScreenCoordinatorParameters(authenticationService: authenticationService,
                                                          loginHint: loginHint,
                                                          userIndicatorController: userIndicatorController,
                                                          appSettings: appSettings,
                                                          analytics: analytics)
        let coordinator = LoginScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .signedIn(let userSession):
                    stateMachine.tryEvent(.signedIn, userInfo: userSession)
                case .configuredForOIDC:
                    // Pop back to the confirmation screen for OIDC login to continue.
                    navigationStackCoordinator.pop(animated: false)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.cancelledPasswordLogin(previousState: fromState))
        }
    }
    
    // MARK: - Bug Report
    
    private func startBugReportFlow() {
        let coordinator = BugReportFlowCoordinator(parameters: .init(presentationMode: .sheet(navigationStackCoordinator),
                                                                     userIndicatorController: userIndicatorController,
                                                                     bugReportService: bugReportService,
                                                                     userSession: nil))
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.stateMachine.tryEvent(.bugReportFlowComplete)
            }
        }
        .store(in: &cancellables)
        
        bugReportFlowCoordinator = coordinator
        coordinator.start()
    }
    
    // MARK: - Completion
        
    private func userHasSignedIn(userSession: UserSessionProtocol) {
        delegate?.authenticationFlowCoordinator(didLoginWithSession: userSession)
    }
}
