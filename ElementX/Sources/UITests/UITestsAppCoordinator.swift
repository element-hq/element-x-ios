//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI
import UIKit

class UITestsAppCoordinator: AppCoordinatorProtocol, SecureWindowManagerDelegate {
    private let navigationRootCoordinator: NavigationRootCoordinator
    
    // periphery:ignore - retaining purpose
    private var mockScreen: MockScreen?
    
    // periphery:ignore - retaining purpose
    private var alternateWindowMockScreen: MockScreen?
    
    let windowManager: SecureWindowManagerProtocol
    
    init(appDelegate: AppDelegate) {
        windowManager = WindowManager(appDelegate: appDelegate)
        // disabling View animations
        UIView.setAnimationsEnabled(false)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        windowManager.delegate = self
        
        MXLog.configure(currentTarget: "uitests")
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.uitests")
        AppSettings.resetAllSettings()
        ServiceLocator.shared.register(appSettings: AppSettings())
        
        let analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: ServiceLocator.shared.settings))
    }
    
    func start() {
        guard let screenID = ProcessInfo.testScreenID else { fatalError("Unable to launch with unknown screen.") }
        
        let mockScreen = MockScreen(id: screenID, windowManager: windowManager, navigationRootCoordinator: navigationRootCoordinator)
        
        if let coordinator = mockScreen.coordinator {
            navigationRootCoordinator.setRootCoordinator(coordinator)
        }
        
        self.mockScreen = mockScreen
    }
    
    func toPresentable() -> AnyView {
        navigationRootCoordinator.toPresentable()
    }
    
    func handlePotentialPhishingAttempt(url: URL, openURLAction: @escaping (URL) -> Void) -> Bool {
        fatalError("Not implemented.")
    }
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        fatalError("Not implemented.")
    }
    
    func handleUserActivity(_ activity: NSUserActivity) {
        fatalError("Not implemented.")
    }
    
    func windowManagerDidConfigureWindows(_ windowManager: SecureWindowManagerProtocol) {
        ServiceLocator.shared.userIndicatorController.window = windowManager.overlayWindow
        
        // Set up the alternate window for the App Lock flow coordinator tests.
        guard let screenID = ProcessInfo.testScreenID, screenID == .appLockFlow || screenID == .appLockFlowDisabled else { return }
        let screen = MockScreen(id: screenID == .appLockFlow ? .appLockFlowAlternateWindow : .appLockFlowDisabledAlternateWindow,
                                windowManager: windowManager,
                                navigationRootCoordinator: navigationRootCoordinator)
        
        guard let coordinator = screen.coordinator else {
            fatalError()
        }
        
        windowManager.alternateWindow.rootViewController = UIHostingController(rootView: coordinator.toPresentable().statusBarHidden())
        
        alternateWindowMockScreen = screen
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestsScreenIdentifier
    let windowManager: SecureWindowManagerProtocol
    let navigationRootCoordinator: NavigationRootCoordinator
    
    private var client: UITestsSignalling.Client?
    
    private var retainedState = [Any]()
    private var cancellables = Set<AnyCancellable>()
    
    init(id: UITestsScreenIdentifier,
         windowManager: SecureWindowManagerProtocol,
         navigationRootCoordinator: NavigationRootCoordinator) {
        self.id = id
        self.windowManager = windowManager
        self.navigationRootCoordinator = navigationRootCoordinator
    }
    
    lazy var coordinator: CoordinatorProtocol? = {
        switch id {
        case .serverSelection:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ServerSelectionScreenCoordinator(parameters: .init(authenticationService: AuthenticationService.mock,
                                                                                 authenticationFlow: .login,
                                                                                 appSettings: ServiceLocator.shared.settings,
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .authenticationFlow, .provisionedAuthenticationFlow, .singleProviderAuthenticationFlow, .multipleProvidersAuthenticationFlow:
            let appSettings: AppSettings! = ServiceLocator.shared.settings
            
            if id == .singleProviderAuthenticationFlow || id == .multipleProvidersAuthenticationFlow {
                let accountProviders = id == .singleProviderAuthenticationFlow ? ["example.com"] : ["guest.example.com", "example.com"]
                appSettings.override(accountProviders: accountProviders,
                                     allowOtherAccountProviders: false,
                                     hideBrandChrome: false,
                                     pushGatewayBaseURL: appSettings.pushGatewayBaseURL,
                                     oidcRedirectURL: appSettings.oidcRedirectURL,
                                     websiteURL: appSettings.websiteURL,
                                     logoURL: appSettings.logoURL,
                                     copyrightURL: appSettings.copyrightURL,
                                     acceptableUseURL: appSettings.acceptableUseURL,
                                     privacyURL: appSettings.privacyURL,
                                     encryptionURL: appSettings.encryptionURL,
                                     deviceVerificationURL: appSettings.deviceVerificationURL,
                                     chatBackupDetailsURL: appSettings.chatBackupDetailsURL,
                                     identityPinningViolationDetailsURL: appSettings.identityPinningViolationDetailsURL,
                                     elementWebHosts: appSettings.elementWebHosts,
                                     accountProvisioningHost: appSettings.accountProvisioningHost,
                                     bugReportApplicationID: appSettings.bugReportApplicationID,
                                     analyticsTermsURL: appSettings.analyticsTermsURL,
                                     mapTilerConfiguration: appSettings.mapTilerConfiguration)
            }
            
            let flowCoordinator = AuthenticationFlowCoordinator(authenticationService: AuthenticationService.mock,
                                                                bugReportService: BugReportServiceMock(.init()),
                                                                navigationRootCoordinator: navigationRootCoordinator,
                                                                appMediator: AppMediatorMock.default,
                                                                appSettings: appSettings,
                                                                analytics: ServiceLocator.shared.analytics,
                                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
            flowCoordinator.start()
            retainedState.append(flowCoordinator)
            
            if id == .provisionedAuthenticationFlow {
                flowCoordinator.handleAppRoute(.accountProvisioningLink(.init(accountProvider: "example.com", loginHint: nil)), animated: false)
            }
            
            return nil
        case .appLockFlow, .appLockFlowDisabled:
            // The tested coordinator is setup below in the alternate window.
            // Here we just return a blank screen to snapshot as the unlocked app.
            return BlankFormCoordinator()
        case .appLockFlowAlternateWindow, .appLockFlowDisabledAlternateWindow:
            let navigationCoordinator = NavigationRootCoordinator()
            
            let keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
            keychainController.resetSecrets()
            
            let context = LAContextMock()
            context.biometryTypeValue = UIDevice.current.isPhone ? .faceID : .touchID // (iPhone 14 & iPad 9th gen)
            context.evaluatePolicyReturnValue = true
            context.evaluatedPolicyDomainStateValue = Data("😎".utf8)
            
            let appLockService = AppLockService(keychainController: keychainController,
                                                appSettings: ServiceLocator.shared.settings,
                                                context: context)
            
            if id == .appLockFlowAlternateWindow {
                let pinCode = "2023"
                guard case .success = appLockService.setupPINCode(pinCode),
                      appLockService.unlock(with: pinCode) else {
                    fatalError("Failed to preset the PIN code.")
                }
            }
            
            let notificationCenter = UITestsNotificationCenter()
            do {
                try notificationCenter.startListening()
            } catch {
                fatalError("Failed to start listening for notifications.")
            }
            
            let flowCoordinator = AppLockFlowCoordinator(initialState: .unlocked,
                                                         appLockService: appLockService,
                                                         navigationCoordinator: navigationCoordinator,
                                                         notificationCenter: notificationCenter,
                                                         appSettings: ServiceLocator.shared.settings)
            
            flowCoordinator.actions
                .sink { [weak self] action in
                    guard let self else { return }
                    
                    switch action {
                    case .lockApp:
                        windowManager.switchToAlternate()
                    case .unlockApp:
                        windowManager.switchToMain()
                    case .forceLogout:
                        break
                    }
                }
                .store(in: &cancellables)
            
            retainedState.append(flowCoordinator)
            
            return navigationCoordinator
        case .appLockSetupFlow, .appLockSetupFlowUnlock, .appLockSetupFlowMandatory:
            let navigationStackCoordinator = NavigationStackCoordinator()
            // The flow expects an existing root coordinator, use a blank form as a placeholder.
            navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
            
            let keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
            keychainController.resetSecrets()
            
            let context = LAContextMock()
            context.biometryTypeValue = UIDevice.current.isPhone ? .faceID : .touchID // (iPhone 14 & iPad 9th gen)
            context.evaluatePolicyReturnValue = true
            context.evaluatedPolicyDomainStateValue = Data("😎".utf8)
            
            let appLockService = AppLockService(keychainController: keychainController,
                                                appSettings: ServiceLocator.shared.settings,
                                                context: context)
            if id == .appLockSetupFlowUnlock, case .failure = appLockService.setupPINCode("2023") {
                fatalError("Failed to pre-set the PIN code")
            }
            
            let flow: AppLockSetupFlowCoordinator.PresentationFlow = id == .appLockSetupFlowMandatory ? .onboarding : .settings
            let flowCoordinator = AppLockSetupFlowCoordinator(presentingFlow: flow,
                                                              appLockService: appLockService,
                                                              navigationStackCoordinator: navigationStackCoordinator)
            flowCoordinator.start()
            
            retainedState.append(flowCoordinator)
            
            return navigationStackCoordinator
        case .bugReport:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
            let userSession = UserSessionMock(.init(clientProxy: clientProxy))
            let coordinator = BugReportScreenCoordinator(parameters: .init(bugReportService: BugReportServiceMock(.init()),
                                                                           userSession: userSession,
                                                                           userIndicatorController: nil,
                                                                           screenshot: nil,
                                                                           isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomPlainNoAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Some room name", avatarURL: nil)),
                                                             timelineController: MockTimelineController(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                             userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimeline:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "New room", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                             userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineWithReactions:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.default
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "New room", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineWithReadReceipts:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunkWithReadReceipts
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "New room", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineIncomingAndSmallPagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.singleMessageChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Small timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineLargePagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Small timeline, paginating", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()), timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutTop:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Large timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutMiddle:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Large timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutBottom:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Large timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutHighlight:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.permalinkChunk
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Timeline highlight", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            
            do {
                let client = try UITestsSignalling.Client(mode: .app)
                client.signals.sink { [weak self] signal in
                    guard case .timeline(.focusOnEvent(let eventID)) = signal else { return }
                    coordinator.focusOnEvent(.init(eventID: eventID, shouldSetPin: false))
                    try? client.send(.success)
                }
                .store(in: &cancellables)
            } catch {
                fatalError("Failure setting up signalling: \(error)")
            }
            
            self.client = client
            return navigationStackCoordinator
        case .roomWithDisclosedPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.disclosedPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Polls timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomWithUndisclosedPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.undisclosedPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Polls timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomWithOutgoingPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.outgoingPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(userSession: UserSessionMock(.init()),
                                                             roomProxy: JoinedRoomProxyMock(.init(name: "Polls timeline", avatarURL: .mockMXCAvatar)),
                                                             timelineController: timelineController,
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                             linkMetadataProvider: LinkMetadataProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             ongoingCallRoomIDPublisher: .init(.init(nil)),
                                                             appMediator: AppMediatorMock.default,
                                                             appSettings: ServiceLocator.shared.settings,
                                                             appHooks: AppHooks(),
                                                             analytics: ServiceLocator.shared.analytics,
                                                             composerDraftService: ComposerDraftServiceMock(.init()),
                                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()), userIndicatorController: UserIndicatorControllerMock())
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .sessionVerification:
            var sessionVerificationControllerProxy = SessionVerificationControllerProxyMock.configureMock(requestDelay: .seconds(5))
            let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationControllerProxy,
                                                                            flow: .deviceInitiator,
                                                                            appSettings: ServiceLocator.shared.settings,
                                                                            mediaProvider: MediaProviderMock(configuration: .init()))
            return SessionVerificationScreenCoordinator(parameters: parameters)
        case .userSessionScreen, .userSessionScreenReply, .userSessionSpacesFlow:
            let appSettings: AppSettings = ServiceLocator.shared.settings
            appSettings.hasRunIdentityConfirmationOnboarding = true
            appSettings.hasRunNotificationPermissionsOnboarding = true
            appSettings.analyticsConsentState = .optedOut
            appSettings.hasSeenSpacesAnnouncement = true
            
            let roomSummaries: [RoomSummary] = if id == .userSessionSpacesFlow {
                [[RoomSummary].mockSpaceInvites[0]] + .mockRooms
            } else {
                .mockRooms
            }
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com",
                                                    deviceID: "MOCKCLIENT",
                                                    roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(roomSummaries))),
                                                    spaceServiceConfiguration: .init(joinedSpaces: .mockSingleRoom),
                                                    roomPreviews: [SpaceRoomProxyProtocol].mockSpaceList.map(RoomPreviewProxyMock.init)))
            
            // The tab bar remains hidden for the non-spaces tests as we don't supply any mock spaces.
            let spaceServiceProxy = SpaceServiceProxyMock(id == .userSessionSpacesFlow ? .populated : .init())
            clientProxy.spaceService = spaceServiceProxy
            
            let appMediator = AppMediatorMock.default
            appMediator.underlyingWindowManager = windowManager

            let flowCoordinator = UserSessionFlowCoordinator(isNewLogin: false,
                                                             navigationRootCoordinator: navigationRootCoordinator,
                                                             appLockService: AppLockService(keychainController: KeychainControllerMock(),
                                                                                            appSettings: ServiceLocator.shared.settings),
                                                             flowParameters: CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                                                  bugReportService: BugReportServiceMock(.init()),
                                                                                                  elementCallService: ElementCallServiceMock(.init()),
                                                                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                                                                  appMediator: appMediator,
                                                                                                  appSettings: appSettings,
                                                                                                  appHooks: AppHooks(),
                                                                                                  analytics: ServiceLocator.shared.analytics,
                                                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                                                  notificationManager: NotificationManagerMock(),
                                                                                                  stateMachineFactory: StateMachineFactory()))

            flowCoordinator.start()
            
            retainedState.append(flowCoordinator)
            
            return nil
        case .roomMembersListScreenPendingInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockInvitedAlice, .mockBob, .mockCharlie]
            let coordinator = RoomMembersListScreenCoordinator(parameters: .init(userSession: UserSessionMock(.init()),
                                                                                 roomProxy: JoinedRoomProxyMock(.init(name: "test", members: members)),
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                                 analytics: ServiceLocator.shared.analytics))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomRolesAndPermissionsFlow:
            let navigationStackCoordinator = NavigationStackCoordinator()
            navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
            let coordinator = RoomRolesAndPermissionsFlowCoordinator(parameters: .init(roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)),
                                                                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                                                                       navigationStackCoordinator: navigationStackCoordinator,
                                                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                                       analytics: ServiceLocator.shared.analytics))
            retainedState.append(coordinator)
            coordinator.start()
            return navigationStackCoordinator
        case .startChatFlow:
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com"))
            clientProxy.createRoomNameTopicIsRoomPrivateIsKnockingOnlyUserIDsAvatarURLAliasLocalPartReturnValue = .success("!new-room:client.com")
            clientProxy.roomForIdentifierClosure = { roomID in .joined(JoinedRoomProxyMock(.init(id: roomID, members: []))) }
            
            let userDiscoveryService = UserDiscoveryServiceMock()
            userDiscoveryService.searchProfilesWithReturnValue = .success([.mockBob, .mockBobby])
            
            let navigationStackCoordinator = NavigationStackCoordinator()
            let flowCoordinator = StartChatFlowCoordinator(userDiscoveryService: userDiscoveryService,
                                                           navigationStackCoordinator: navigationStackCoordinator,
                                                           flowParameters: CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                                                bugReportService: BugReportServiceMock(.init()),
                                                                                                elementCallService: ElementCallServiceMock(.init()),
                                                                                                timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                                                                emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                                                                linkMetadataProvider: LinkMetadataProvider(),
                                                                                                appMediator: AppMediatorMock.default,
                                                                                                appSettings: ServiceLocator.shared.settings,
                                                                                                appHooks: AppHooks(),
                                                                                                analytics: ServiceLocator.shared.analytics,
                                                                                                userIndicatorController: UserIndicatorControllerMock(),
                                                                                                notificationManager: NotificationManagerMock(),
                                                                                                stateMachineFactory: StateMachineFactory()))
            flowCoordinator.actionsPublisher
                .sink { [weak self] action in
                    guard let self else { return }
                    switch action {
                    case .finished(let roomID):
                        navigationRootCoordinator.setSheetCoordinator(nil)
                    case .showRoomDirectory:
                        break // The test doesn't cover this.
                    }
                }
                .store(in: &cancellables)
            
            retainedState.append(flowCoordinator)
            flowCoordinator.start()
            
            // Use a sheet on top the the placeholder so we can test the dismissal.
            navigationRootCoordinator.setSheetCoordinator(navigationStackCoordinator)
            return PlaceholderScreenCoordinator(hideBrandChrome: false)
        case .createPoll:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = PollFormScreenCoordinator(parameters: .init(mode: .new,
                                                                          maxNumberOfOptions: 10,
                                                                          timelineController: MockTimelineController(),
                                                                          analytics: ServiceLocator.shared.analytics,
                                                                          userIndicatorController: UserIndicatorControllerMock()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .encryptionSettings, .encryptionSettingsOutOfSync:
            let recoveryState: SecureBackupRecoveryState = id == .encryptionSettings ? .enabled : .incomplete
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com", recoveryState: recoveryState))
            let userSession = UserSessionMock(.init(clientProxy: clientProxy))
            
            let navigationStackCoordinator = NavigationStackCoordinator()
            navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
            
            let coordinator = EncryptionSettingsFlowCoordinator(parameters: .init(userSession: userSession,
                                                                                  appSettings: ServiceLocator.shared.settings,
                                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                                  navigationStackCoordinator: navigationStackCoordinator))
            retainedState.append(coordinator)
            coordinator.start()
            
            return navigationStackCoordinator
        case .encryptionReset:
            let recoveryState: SecureBackupRecoveryState = id == .encryptionSettings ? .enabled : .incomplete
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com", recoveryState: recoveryState))
            let userSession = UserSessionMock(.init(clientProxy: clientProxy))
            
            let userIndicatorController = UserIndicatorController()
            userIndicatorController.window = windowManager.overlayWindow
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let coordinator = EncryptionResetFlowCoordinator(parameters: .init(userSession: userSession,
                                                                               appSettings: ServiceLocator.shared.settings,
                                                                               userIndicatorController: userIndicatorController,
                                                                               navigationStackCoordinator: navigationStackCoordinator,
                                                                               windowManger: windowManager))

            retainedState.append(coordinator)
            coordinator.start()
            
            return navigationStackCoordinator
        case .autoUpdatingTimeline:
            let appSettings: AppSettings = ServiceLocator.shared.settings
            appSettings.hasRunIdentityConfirmationOnboarding = true
            appSettings.hasRunNotificationPermissionsOnboarding = true
            appSettings.analyticsConsentState = .optedOut
            let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: false))
            navigationRootCoordinator.setRootCoordinator(navigationSplitCoordinator)
            
            let clientProxy = ClientProxyMock(.init(userID: "@mock:client.com", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
            
            let roomProxy = JoinedRoomProxyMock(.init(id: "whatever", name: "okay", shouldUseAutoUpdatingTimeline: true))
            
            clientProxy.roomForIdentifierReturnValue = .joined(roomProxy)
            
            let timelineController = TimelineController(roomProxy: roomProxy,
                                                        timelineProxy: roomProxy.timeline,
                                                        initialFocussedEventID: nil,
                                                        timelineItemFactory: RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                                                                                     attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                                                                     stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org")),
                                                        mediaProvider: MediaProviderMock(configuration: .init()),
                                                        appSettings: ServiceLocator.shared.settings)
            
            let flowCoordinator = ChatsFlowCoordinator(isNewLogin: false,
                                                       navigationSplitCoordinator: navigationSplitCoordinator,
                                                       flowParameters: CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                                            bugReportService: BugReportServiceMock(.init()),
                                                                                            elementCallService: ElementCallServiceMock(.init()),
                                                                                            timelineControllerFactory: TimelineControllerFactoryMock(.init(timelineController: timelineController)),
                                                                                            emojiProvider: EmojiProvider(appSettings: appSettings),
                                                                                            linkMetadataProvider: LinkMetadataProvider(),
                                                                                            appMediator: AppMediatorMock.default,
                                                                                            appSettings: appSettings,
                                                                                            appHooks: AppHooks(),
                                                                                            analytics: ServiceLocator.shared.analytics,
                                                                                            userIndicatorController: UserIndicatorControllerMock(),
                                                                                            notificationManager: NotificationManagerMock(),
                                                                                            stateMachineFactory: StateMachineFactory()))

            flowCoordinator.start()
            
            retainedState.append(flowCoordinator)
            
            return nil
        }
    }()
}
