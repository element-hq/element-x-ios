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

import SwiftUI
import UIKit

class UITestsAppCoordinator: AppCoordinatorProtocol {
    private let navigationRootCoordinator: NavigationRootCoordinator
    private var mockScreens: [MockScreen] = []
    var notificationManager: NotificationManagerProtocol?
    
    init() {
        UIView.setAnimationsEnabled(false)
        navigationRootCoordinator = NavigationRootCoordinator()
        mockScreens = UITestScreenIdentifier.allCases.map { MockScreen(id: $0, navigationRootCoordinator: navigationRootCoordinator) }
        
        ServiceLocator.shared.register(userNotificationController: MockUserNotificationController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.uitests")
        AppSettings.reset()
        ServiceLocator.shared.register(appSettings: AppSettings())
    }
    
    func start() {
        let rootCoordinator = UITestsRootCoordinator(mockScreens: mockScreens) { id in
            guard let screen = self.mockScreens.first(where: { $0.id == id }) else {
                fatalError()
            }
            
            self.navigationRootCoordinator.setRootCoordinator(screen.coordinator)
        }
        
        navigationRootCoordinator.setRootCoordinator(rootCoordinator)
        
        Bundle.elementFallbackLanguage = "en"
    }
    
    func toPresentable() -> AnyView {
        navigationRootCoordinator.toPresentable()
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestScreenIdentifier
    
    private let navigationRootCoordinator: NavigationRootCoordinator
    private var retainedState = [Any]()
    
    init(id: UITestScreenIdentifier, navigationRootCoordinator: NavigationRootCoordinator) {
        self.id = id
        self.navigationRootCoordinator = navigationRootCoordinator
    }
    
    lazy var coordinator: CoordinatorProtocol = {
        switch id {
        case .login:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = LoginCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                 navigationStackCoordinator: navigationStackCoordinator))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverSelection:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                           userNotificationController: MockUserNotificationController(),
                                                                           isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverSelectionNonModal:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                userNotificationController: MockUserNotificationController(),
                                                                isModallyPresented: false))
        case .analyticsPrompt:
            return AnalyticsPromptCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"),
                                                                                             mediaProvider: MockMediaProvider())))
        case .authenticationFlow:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = AuthenticationCoordinator(authenticationService: MockAuthenticationServiceProxy(),
                                                        navigationStackCoordinator: navigationStackCoordinator)
            retainedState.append(coordinator)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .softLogout:
            let credentials = SoftLogoutCredentials(userId: "@mock:matrix.org",
                                                    homeserverName: "matrix.org",
                                                    userDisplayName: "mock",
                                                    deviceId: "ABCDEFGH")
            return SoftLogoutCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                           credentials: credentials,
                                                           keyBackupNeeded: false))
        case .simpleRegular:
            return TemplateCoordinator(parameters: .init(promptType: .regular))
        case .simpleUpgrade:
            return TemplateCoordinator(parameters: .init(promptType: .upgrade))
        case .home:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let session = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider())
            let coordinator = HomeScreenCoordinator(parameters: .init(userSession: session,
                                                                      attributedStringBuilder: AttributedStringBuilder(),
                                                                      bugReportService: MockBugReportService(),
                                                                      navigationStackCoordinator: navigationStackCoordinator))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .settings:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = SettingsScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                          userNotificationController: MockUserNotificationController(),
                                                                          userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"),
                                                                                                       mediaProvider: MockMediaProvider()),
                                                                          bugReportService: MockBugReportService()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .bugReport:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                                     userNotificationController: MockUserNotificationController(),
                                                                     screenshot: nil,
                                                                     isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .bugReportWithScreenshot:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                                     userNotificationController: MockUserNotificationController(),
                                                                     screenshot: Asset.Images.appLogo.image,
                                                                     isModallyPresented: false))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .onboarding:
            return OnboardingCoordinator()
        case .roomPlainNoAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Some room name", avatarURL: nil),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomEncryptedWithAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Some room name", avatarURL: URL.picturesDirectory),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimeline:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "New room", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineIncomingAndSmallPagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.singleMessageChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Small timeline", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineLargePagination:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Small timeline, paginating", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutTop:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Large timeline", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)

            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutMiddle:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.backPaginationResponses = [RoomTimelineItemFixtures.largeChunk]
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Large timeline", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomLayoutBottom:
            let navigationStackCoordinator = NavigationStackCoordinator()
            
            let timelineController = MockRoomTimelineController(listenForSignals: true)
            timelineController.timelineItems = RoomTimelineItemFixtures.largeChunk
            timelineController.incomingItems = [RoomTimelineItemFixtures.incomingMessage]
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: MockRoomProxy(displayName: "Large timeline", avatarURL: URL.picturesDirectory),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .sessionVerification:
            var sessionVerificationControllerProxy = MockSessionVerificationControllerProxy()
            sessionVerificationControllerProxy.requestDelay = .seconds(2)
            let parameters = SessionVerificationCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationControllerProxy)
            return SessionVerificationCoordinator(parameters: parameters)
        case .userSessionScreen:
            let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
            
            let clientProxy = MockClientProxy(userID: "@mock:client.com", roomSummaryProvider: MockRoomSummaryProvider(state: .loaded))
            
            let coordinator = UserSessionFlowCoordinator(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider()),
                                                         navigationSplitCoordinator: navigationSplitCoordinator,
                                                         bugReportService: MockBugReportService(),
                                                         roomTimelineControllerFactory: MockRoomTimelineControllerFactory())
            
            coordinator.start()
            
            retainedState.append(coordinator)
            
            return navigationSplitCoordinator
        case .roomDetailsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userNotificationController = UserNotificationController(rootCoordinator: navigationStackCoordinator)
            let coordinator = RoomDetailsCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                       roomProxy: MockRoomProxy(displayName: "Room",
                                                                                                isEncrypted: true,
                                                                                                members: [.mockAlice, .mockBob, .mockCharlie]),
                                                                       mediaProvider: MockMediaProvider(),
                                                                       userNotificationController: userNotificationController))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsCoordinator(parameters: .init(mediaProvider: MockMediaProvider(),
                                                                             members: [.mockAlice, .mockBob, .mockCharlie]))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        }
    }()
}
