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

import Combine
import MatrixRustSDK
import SwiftUI
import UIKit

class UITestsAppCoordinator: AppCoordinatorProtocol, WindowManagerDelegate {
    private let navigationRootCoordinator: NavigationRootCoordinator
    private var mockScreen: MockScreen?
    private var alternateWindowMockScreen: MockScreen?
    
    let notificationManager: NotificationManagerProtocol = NotificationManagerMock()
    let windowManager = WindowManager()
    
    init() {
        // disabling View animations
        UIView.setAnimationsEnabled(false)
        
        navigationRootCoordinator = NavigationRootCoordinator()
        
        windowManager.delegate = self
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.uitests")
        AppSettings.reset()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock())
        ServiceLocator.shared.register(analytics: AnalyticsService(client: AnalyticsClientMock(),
                                                                   appSettings: ServiceLocator.shared.settings,
                                                                   bugReportService: ServiceLocator.shared.bugReportService))
    }
    
    func start() {
        guard let screenID = ProcessInfo.testScreenID else { fatalError("Unable to launch with unknown screen.") }
        
        let mockScreen = MockScreen(id: screenID)
        navigationRootCoordinator.setRootCoordinator(mockScreen.coordinator)
        self.mockScreen = mockScreen
    }
    
    func toPresentable() -> AnyView {
        navigationRootCoordinator.toPresentable()
    }
    
    func handleDeepLink(_ url: URL) -> Bool {
        fatalError("Not implemented.")
    }
    
    func windowManagerDidConfigureWindows(_ windowManager: WindowManager) {
        ServiceLocator.shared.userIndicatorController.window = windowManager.overlayWindow
        
        // Set up the alternate window for the App Lock flow coordinator tests.
        guard let screenID = ProcessInfo.testScreenID, screenID == .appLockFlow || screenID == .appLockFlowDisabled else { return }
        let screen = MockScreen(id: screenID == .appLockFlow ? .appLockFlowAlternateWindow : .appLockFlowDisabledAlternateWindow, windowManager: windowManager)
        windowManager.alternateWindow.rootViewController = UIHostingController(rootView: screen.coordinator.toPresentable().statusBarHidden())
        alternateWindowMockScreen = screen
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestsScreenIdentifier
    let windowManager: WindowManager?
    
    private var retainedState = [Any]()
    private var cancellables = Set<AnyCancellable>()
    
    init(id: UITestsScreenIdentifier, windowManager: WindowManager? = nil) {
        self.id = id
        self.windowManager = windowManager
    }
    
    lazy var coordinator: CoordinatorProtocol = {
        switch id {
        case .login:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = LoginScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                       analytics: ServiceLocator.shared.analytics,
                                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverConfirmationLogin:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ServerConfirmationScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(homeserver: .mockMatrixDotOrg),
                                                                                    authenticationFlow: .login))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverConfirmationRegister:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ServerConfirmationScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(homeserver: .mockOIDC),
                                                                                    authenticationFlow: .register))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverSelection:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ServerSelectionScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                                 isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverSelectionNonModal:
            return ServerSelectionScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                      userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                      isModallyPresented: false))
        case .analyticsPrompt:
            return AnalyticsPromptScreenCoordinator(analytics: ServiceLocator.shared.analytics,
                                                    termsURL: ServiceLocator.shared.settings.analyticsConfiguration.termsURL)
        case .analyticsSettingsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = AnalyticsSettingsScreenCoordinator(parameters: .init(appSettings: ServiceLocator.shared.settings,
                                                                                   analytics: ServiceLocator.shared.analytics))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .migration:
            let coordinator = MigrationScreenCoordinator()
            return coordinator
        case .authenticationFlow:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = AuthenticationCoordinator(authenticationService: MockAuthenticationServiceProxy(),
                                                        navigationStackCoordinator: navigationStackCoordinator,
                                                        appSettings: ServiceLocator.shared.settings,
                                                        analytics: ServiceLocator.shared.analytics,
                                                        userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                        appLockService: AppLockServiceMock())
            retainedState.append(coordinator)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .softLogout:
            let credentials = SoftLogoutScreenCredentials(userID: "@mock:matrix.org",
                                                          homeserverName: "matrix.org",
                                                          userDisplayName: "mock",
                                                          deviceID: "ABCDEFGH")
            return SoftLogoutScreenCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                 credentials: credentials,
                                                                 keyBackupNeeded: false,
                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController))
        case .waitlist:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let credentials = WaitlistScreenCredentials(username: "alice",
                                                        password: "password",
                                                        initialDeviceName: nil,
                                                        deviceID: nil,
                                                        homeserver: .mockMatrixDotOrg)
            let coordinator = WaitlistScreenCoordinator(parameters: .init(credentials: credentials,
                                                                          authenticationService: MockAuthenticationServiceProxy(),
                                                                          userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .templateScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = TemplateScreenCoordinator(parameters: .init())
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
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
            context.evaluatedPolicyDomainStateValue = "😎".data(using: .utf8)
            
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
            
            let coordinator = AppLockFlowCoordinator(initialState: .unlocked,
                                                     appLockService: appLockService,
                                                     navigationCoordinator: navigationCoordinator,
                                                     notificationCenter: notificationCenter)
            
            guard let windowManager else { fatalError("The window manager must be supplied.") }
            
            coordinator.actions
                .sink { action in
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
            
            return coordinator
        case .appLockSetupFlow, .appLockSetupFlowUnlock, .appLockSetupFlowMandatory:
            let navigationStackCoordinator = NavigationStackCoordinator()
            // The flow expects an existing root coordinator, use a blank form as a placeholder.
            navigationStackCoordinator.setRootCoordinator(BlankFormCoordinator())
            
            let keychainController = KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
            keychainController.resetSecrets()
            
            let context = LAContextMock()
            context.biometryTypeValue = UIDevice.current.isPhone ? .faceID : .touchID // (iPhone 14 & iPad 9th gen)
            context.evaluatePolicyReturnValue = true
            context.evaluatedPolicyDomainStateValue = "😎".data(using: .utf8)
            
            let appLockService = AppLockService(keychainController: keychainController,
                                                appSettings: ServiceLocator.shared.settings,
                                                context: context)
            if id == .appLockSetupFlowUnlock, case .failure = appLockService.setupPINCode("2023") {
                fatalError("Failed to pre-set the PIN code")
            }
            
            let flow: AppLockSetupFlowCoordinator.PresentationFlow = id == .appLockSetupFlowMandatory ? .onboarding : .settings
            let coordinator = AppLockSetupFlowCoordinator(presentingFlow: flow,
                                                          appLockService: appLockService,
                                                          navigationStackCoordinator: navigationStackCoordinator)
            coordinator.start()
            retainedState.append(coordinator)
            
            return navigationStackCoordinator
        case .home:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let session = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let coordinator = HomeScreenCoordinator(parameters: .init(userSession: session,
                                                                      attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL, mentionBuilder: MentionBuilder()),
                                                                      bugReportService: BugReportServiceMock(),
                                                                      navigationStackCoordinator: navigationStackCoordinator,
                                                                      selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .settings:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let coordinator = SettingsScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: UserIndicatorControllerMock(),
                                                                          userSession: MockUserSession(clientProxy: clientProxy,
                                                                                                       mediaProvider: MockMediaProvider(),
                                                                                                       voiceMessageMediaManager: VoiceMessageMediaManagerMock()),
                                                                          appLockService: AppLockService(keychainController: KeychainControllerMock(),
                                                                                                         appSettings: ServiceLocator.shared.settings),
                                                                          bugReportService: BugReportServiceMock(),
                                                                          notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                          secureBackupController: SecureBackupControllerMock(),
                                                                          appSettings: ServiceLocator.shared.settings))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .bugReport:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = BugReportScreenCoordinator(parameters: .init(bugReportService: BugReportServiceMock(),
                                                                           userID: "@mock:client.com",
                                                                           deviceID: nil,
                                                                           userIndicatorController: nil,
                                                                           screenshot: nil,
                                                                           isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .bugReportWithScreenshot:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = BugReportScreenCoordinator(parameters: .init(bugReportService: BugReportServiceMock(),
                                                                           userID: "@mock:client.com",
                                                                           deviceID: nil,
                                                                           userIndicatorController: nil,
                                                                           screenshot: Asset.Images.appLogo.image,
                                                                           isModallyPresented: false))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .notificationSettingsScreen:
            let userNotificationCenter = UserNotificationCenterMock()
            userNotificationCenter.authorizationStatusReturnValue = .denied
            let session = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let parameters = NotificationSettingsScreenCoordinatorParameters(userSession: session,
                                                                             userNotificationCenter: userNotificationCenter,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             isModallyPresented: false)
            return NotificationSettingsScreenCoordinator(parameters: parameters)
        case .notificationSettingsScreenMismatchConfiguration:
            let userNotificationCenter = UserNotificationCenterMock()
            userNotificationCenter.authorizationStatusReturnValue = .denied
            let session = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let notificationSettings = NotificationSettingsProxyMock(with: .init())
            notificationSettings.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
                switch (isEncrypted, isOneToOne) {
                case (true, _):
                    return .allMessages
                case (false, _):
                    return .mentionsAndKeywordsOnly
                }
            }
            let parameters = NotificationSettingsScreenCoordinatorParameters(userSession: session,
                                                                             userNotificationCenter: userNotificationCenter,
                                                                             notificationSettings: notificationSettings,
                                                                             isModallyPresented: false)
            return NotificationSettingsScreenCoordinator(parameters: parameters)
        case .onboarding:
            return OnboardingScreenCoordinator()
        case .roomPlainNoAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: nil)),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomEncryptedWithAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: URL.picturesDirectory)),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimeline:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineWithReactions:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.default
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineWithReadReceipts:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunkWithReadReceipts
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineIncomingAndSmallPagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.singleMessageChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineLargePagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline, paginating", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutTop:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutMiddle:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutBottom:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomWithDisclosedPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.disclosedPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Polls timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomWithUndisclosedPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.undisclosedPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Polls timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomWithOutgoingPolls:
            let navigationStackCoordinator = NavigationStackCoordinator()

            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.outgoingPolls
            timelineController.incomingItems = []
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Polls timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                             emojiProvider: EmojiProvider(),
                                                             completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                             appSettings: ServiceLocator.shared.settings)
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .sessionVerification:
            var sessionVerificationControllerProxy = SessionVerificationControllerProxyMock.configureMock(requestDelay: .seconds(5))
            let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationControllerProxy)
            return SessionVerificationScreenCoordinator(parameters: parameters)
        case .userSessionScreen, .userSessionScreenReply, .userSessionScreenRTE:
            let appSettings: AppSettings = ServiceLocator.shared.settings
            appSettings.richTextEditorEnabled = id == .userSessionScreenRTE
            let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
            
            let clientProxy = MockClientProxy(userID: "@mock:client.com", roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms)))
            ServiceLocator.shared.settings.migratedAccounts[clientProxy.userID] = true
            ServiceLocator.shared.settings.hasShownWelcomeScreen = true
            
            let coordinator = UserSessionFlowCoordinator(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock()),
                                                         navigationSplitCoordinator: navigationSplitCoordinator,
                                                         appLockService: AppLockService(keychainController: KeychainControllerMock(),
                                                                                        appSettings: ServiceLocator.shared.settings),
                                                         bugReportService: BugReportServiceMock(),
                                                         roomTimelineControllerFactory: MockRoomTimelineControllerFactory(),
                                                         appSettings: appSettings,
                                                         analytics: ServiceLocator.shared.analytics)
            
            coordinator.start()
            
            retainedState.append(coordinator)
            
            return navigationSplitCoordinator
        case .roomDetailsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockCharlie]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      isEncrypted: true,
                                                      members: members,
                                                      memberForID: .mockOwner(allowedStateEvents: [], canInviteUsers: false),
                                                      activeMembersCount: members.count))
            let coordinator = RoomDetailsScreenCoordinator(parameters: .init(accountUserID: "@owner:somewhere.com",
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                                              mentionBuilder: MentionBuilder())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomDetailsScreenWithRoomAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockCharlie]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      topic: "Bacon ipsum dolor amet commodo incididunt ribeye dolore cupidatat short ribs.",
                                                      avatarURL: URL.picturesDirectory,
                                                      isEncrypted: true,
                                                      canonicalAlias: "#mock:room.org",
                                                      members: members,
                                                      memberForID: .mockOwner(allowedStateEvents: [], canInviteUsers: false),
                                                      activeMembersCount: members.count))
            let coordinator = RoomDetailsScreenCoordinator(parameters: .init(accountUserID: "@owner:somewhere.com",
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                                              mentionBuilder: MentionBuilder())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomDetailsScreenWithEmptyTopic:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [.roomTopic], canInviteUsers: false)
            let members: [RoomMemberProxyMock] = [owner, .mockBob, .mockCharlie]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      topic: nil,
                                                      avatarURL: URL.picturesDirectory,
                                                      isDirect: false,
                                                      isEncrypted: true,
                                                      canonicalAlias: "#mock:room.org",
                                                      members: members,
                                                      memberForID: owner,
                                                      activeMembersCount: members.count))
            let coordinator = RoomDetailsScreenCoordinator(parameters: .init(accountUserID: "@owner:somewhere.com",
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                                              mentionBuilder: MentionBuilder())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomDetailsScreenWithInvite:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let owner: RoomMemberProxyMock = .mockOwner(allowedStateEvents: [], canInviteUsers: true)
            let members: [RoomMemberProxyMock] = [owner, .mockBob, .mockCharlie]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      isEncrypted: true,
                                                      members: members,
                                                      memberForID: owner,
                                                      activeMembersCount: members.count))
            let coordinator = RoomDetailsScreenCoordinator(parameters: .init(accountUserID: "@owner:somewhere.com",
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                                              mentionBuilder: MentionBuilder())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomDetailsScreenDmDetails:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockMe, .mockDan]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      topic: "test",
                                                      isDirect: true,
                                                      isEncrypted: true,
                                                      members: members,
                                                      memberForID: .mockOwner(allowedStateEvents: [], canInviteUsers: false),
                                                      activeMembersCount: members.count))
            let coordinator = RoomDetailsScreenCoordinator(parameters: .init(accountUserID: "@owner:somewhere.com",
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                                             notificationSettings: NotificationSettingsProxyMock(with: .init()),
                                                                             attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL,
                                                                                                                              mentionBuilder: MentionBuilder())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomEditDetails, .roomEditDetailsReadOnly:
            let allowedStateEvents: [StateEventType] = id == .roomEditDetails ? [.roomAvatar, .roomName, .roomTopic] : []
            let navigationStackCoordinator = NavigationStackCoordinator()
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      name: "Room",
                                                      displayName: "Room",
                                                      topic: "What a cool topic!",
                                                      avatarURL: .picturesDirectory))
            let coordinator = RoomDetailsEditScreenCoordinator(parameters: .init(accountOwner: RoomMemberProxyMock.mockOwner(allowedStateEvents: allowedStateEvents),
                                                                                 mediaProvider: MockMediaProvider(),
                                                                                 navigationStackCoordinator: navigationStackCoordinator,
                                                                                 roomProxy: roomProxy,
                                                                                 userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMembersListScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockCharlie]
            let coordinator = RoomMembersListScreenCoordinator(parameters: .init(mediaProvider: MockMediaProvider(),
                                                                                 roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMembersListScreenPendingInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockInvitedAlice, .mockBob, .mockCharlie]
            let coordinator = RoomMembersListScreenCoordinator(parameters: .init(mediaProvider: MockMediaProvider(),
                                                                                 roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomNotificationSettingsDefaultSetting:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockInvitedAlice, .mockBob, .mockCharlie]
            let coordinator = RoomNotificationSettingsScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                                          notificationSettingsProxy: NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .allMessages)),
                                                                                          roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members)),
                                                                                          displayAsUserDefinedRoomSettings: false))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomNotificationSettingsCustomSetting:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockInvitedAlice, .mockBob, .mockCharlie]
            let coordinator = RoomNotificationSettingsScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                                          notificationSettingsProxy: NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly)),
                                                                                          roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members)),
                                                                                          displayAsUserDefinedRoomSettings: false))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .reportContent:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ReportContentScreenCoordinator(parameters: .init(eventID: "test",
                                                                               senderID: RoomMemberProxyMock.mockAlice.userID,
                                                                               roomProxy: RoomProxyMock(with: .init(displayName: "test")),
                                                                               userIndicatorController: UserIndicatorControllerMock()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChat:
            ServiceLocator.shared.settings.userSuggestionsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([.mockAlice, .mockBob, .mockCharlie])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([])
            let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"), mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let parameters: StartChatScreenCoordinatorParameters = .init(userSession: userSession,
                                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                                         userDiscoveryService: userDiscoveryMock)
            let coordinator = StartChatScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChatWithSearchResults:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([.mockBob, .mockBobby])
            let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let coordinator = StartChatScreenCoordinator(parameters: .init(userSession: userSession,
                                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                                           navigationStackCoordinator: navigationStackCoordinator,
                                                                           userDiscoveryService: userDiscoveryMock))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsAccountOwner:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                                                                   roomMemberProxy: RoomMemberProxyMock.mockMe,
                                                                                   mediaProvider: MockMediaProvider(),
                                                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetails:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                                                                   roomMemberProxy: RoomMemberProxyMock.mockAlice,
                                                                                   mediaProvider: MockMediaProvider(),
                                                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsIgnoredUser:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomProxy: RoomProxyMock(with: .init(displayName: "")),
                                                                                   roomMemberProxy: RoomMemberProxyMock.mockIgnored,
                                                                                   mediaProvider: MockMediaProvider(),
                                                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesWithBadges:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.dropFirst(1).compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId1"] = .init(with: .init(displayName: "First room"))
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId2"] = .init(with: .init(displayName: "Second room"))
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.inviteSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invites:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId1"] = .init(with: .init(displayName: "First room"))
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId2"] = .init(with: .init(displayName: "Second room"))
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.inviteSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesNoInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .inviteUsers, .inviteUsersInRoom, .inviteUsersInRoomExistingMembers:
            ServiceLocator.shared.settings.userSuggestionsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([.mockAlice, .mockBob, .mockCharlie])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([])
            let mediaProvider = MockMediaProvider()
            let usersSubject = CurrentValueSubject<[UserProfileProxy], Never>([])
            let members: [RoomMemberProxyMock] = id == .inviteUsersInRoomExistingMembers ? [.mockInvitedAlice, .mockBob] : []
            let roomProxy = RoomProxyMock(with: .init(displayName: "test", members: members))
            let roomType: InviteUsersScreenRoomType = id == .inviteUsers ? .draft : .room(roomProxy: roomProxy)
            let coordinator = InviteUsersScreenCoordinator(parameters: .init(selectedUsers: usersSubject.asCurrentValuePublisher(),
                                                                             roomType: roomType,
                                                                             mediaProvider: mediaProvider,
                                                                             userDiscoveryService: userDiscoveryMock,
                                                                             userIndicatorController: UserIndicatorControllerMock()))
            coordinator.actions.sink { action in
                switch action {
                case .toggleUser(let user):
                    var selectedUsers = usersSubject.value
                    if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
                        selectedUsers.remove(at: index)
                    } else {
                        selectedUsers.append(user)
                    }
                    usersSubject.send(selectedUsers)
                default:
                    break
                }
            }
            .store(in: &cancellables)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .createRoom:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let mockUserSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let createRoomParameters = CreateRoomFlowParameters()
            let selectedUsers: [UserProfileProxy] = [.mockAlice, .mockBob, .mockCharlie]
            let parameters = CreateRoomCoordinatorParameters(userSession: mockUserSession,
                                                             userIndicatorController: UserIndicatorControllerMock(),
                                                             createRoomParameters: .init(createRoomParameters),
                                                             selectedUsers: .init(selectedUsers))
            let coordinator = CreateRoomCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .createRoomNoUsers:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let mockUserSession = MockUserSession(clientProxy: clientProxy,
                                                  mediaProvider: MockMediaProvider(),
                                                  voiceMessageMediaManager: VoiceMessageMediaManagerMock())
            let createRoomParameters = CreateRoomFlowParameters()
            let parameters = CreateRoomCoordinatorParameters(userSession: mockUserSession,
                                                             userIndicatorController: UserIndicatorControllerMock(),
                                                             createRoomParameters: .init(createRoomParameters),
                                                             selectedUsers: .init([]))
            let coordinator = CreateRoomCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .createPoll:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = PollFormScreenCoordinator(parameters: .init(mode: .new))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        }
    }()
}
