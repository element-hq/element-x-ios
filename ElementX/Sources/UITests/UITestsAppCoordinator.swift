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

class UITestsAppCoordinator: AppCoordinatorProtocol {
    private let navigationRootCoordinator: NavigationRootCoordinator
    private var mockScreen: MockScreen?
    let notificationManager: NotificationManagerProtocol = NotificationManagerMock()
    
    init() {
        // disabling View animations
        UIView.setAnimationsEnabled(false)

        navigationRootCoordinator = NavigationRootCoordinator()
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorControllerMock.default)
        
        AppSettings.configureWithSuiteName("io.element.elementx.uitests")
        AppSettings.reset()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock())
        ServiceLocator.shared.register(analytics: AnalyticsService(client: AnalyticsClientMock(),
                                                                   appSettings: ServiceLocator.shared.settings,
                                                                   bugReportService: ServiceLocator.shared.bugReportService))
    }
    
    func start() {
        // disabling CA animations
        UIApplication.shared.connectedScenes.forEach { scene in
            guard let delegate = scene.delegate as? UIWindowSceneDelegate else {
                return
            }
            delegate.window??.layer.speed = 0
        }
        
        guard let screenID = Tests.screenID else { fatalError("Unable to launch with unknown screen.") }
        
        let mockScreen = MockScreen(id: screenID)
        navigationRootCoordinator.setRootCoordinator(mockScreen.coordinator)
        self.mockScreen = mockScreen
    }
    
    func toPresentable() -> AnyView {
        navigationRootCoordinator.toPresentable()
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestsScreenIdentifier
    
    private var retainedState = [Any]()
    private var cancellables: Set<AnyCancellable> = []
    
    init(id: UITestsScreenIdentifier) {
        self.id = id
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
                                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)
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
        case .simpleRegular:
            return TemplateScreenCoordinator(parameters: .init(promptType: .regular))
        case .simpleUpgrade:
            return TemplateScreenCoordinator(parameters: .init(promptType: .upgrade))
        case .home:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let session = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider())
            let coordinator = HomeScreenCoordinator(parameters: .init(userSession: session,
                                                                      attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL),
                                                                      bugReportService: BugReportServiceMock(),
                                                                      navigationStackCoordinator: navigationStackCoordinator,
                                                                      selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .settings:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = SettingsScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: nil,
                                                                          userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"),
                                                                                                       mediaProvider: MockMediaProvider()),
                                                                          bugReportService: BugReportServiceMock()))
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
            let parameters = NotificationSettingsScreenCoordinatorParameters(userNotificationCenter: userNotificationCenter)
            return NotificationSettingsScreenCoordinator(parameters: parameters)
        case .onboarding:
            return OnboardingCoordinator()
        case .roomPlainNoAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: nil)),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomEncryptedWithAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
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
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomSmallTimelineWithReadReceipts:
            ServiceLocator.shared.settings.readReceiptsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let timelineController = MockRoomTimelineController()
            timelineController.timelineItems = RoomTimelineItemFixtures.smallChunkWithReadReceipts
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline, paginating", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
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
            let parameters = RoomScreenCoordinatorParameters(roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .sessionVerification:
            var sessionVerificationControllerProxy = SessionVerificationControllerProxyMock.configureMock(requestDelay: .seconds(5))
            let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationControllerProxy)
            return SessionVerificationScreenCoordinator(parameters: parameters)
        case .userSessionScreen:
            let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
            
            let clientProxy = MockClientProxy(userID: "@mock:client.com", roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms)))
            ServiceLocator.shared.settings.migratedAccounts[clientProxy.userID] = true
            
            let coordinator = UserSessionFlowCoordinator(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider()),
                                                         navigationSplitCoordinator: navigationSplitCoordinator,
                                                         bugReportService: BugReportServiceMock(),
                                                         roomTimelineControllerFactory: MockRoomTimelineControllerFactory(),
                                                         appSettings: ServiceLocator.shared.settings,
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
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userDiscoveryService: UserDiscoveryServiceMock(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController))
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
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userDiscoveryService: UserDiscoveryServiceMock(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController))
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
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userDiscoveryService: UserDiscoveryServiceMock(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController))
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
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userDiscoveryService: UserDiscoveryServiceMock(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController))
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
                                                                             navigationStackCoordinator: navigationStackCoordinator,
                                                                             roomProxy: roomProxy,
                                                                             mediaProvider: MockMediaProvider(),
                                                                             userDiscoveryService: UserDiscoveryServiceMock(),
                                                                             userIndicatorController: ServiceLocator.shared.userIndicatorController))
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
            let coordinator = RoomMembersListScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                                 mediaProvider: MockMediaProvider(),
                                                                                 roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMembersListScreenPendingInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockInvitedAlice, .mockBob, .mockCharlie]
            let coordinator = RoomMembersListScreenCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                                 mediaProvider: MockMediaProvider(),
                                                                                 roomProxy: RoomProxyMock(with: .init(displayName: "test", members: members))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .reportContent:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ReportContentScreenCoordinator(parameters: .init(itemID: "test",
                                                                               senderID: RoomMemberProxyMock.mockAlice.userID,
                                                                               roomProxy: RoomProxyMock(with: .init(displayName: "test"))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChat:
            ServiceLocator.shared.settings.userSuggestionsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([.mockAlice, .mockBob, .mockCharlie])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([])
            let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"), mediaProvider: MockMediaProvider())
            let parameters: StartChatScreenCoordinatorParameters = .init(userSession: userSession, navigationStackCoordinator: navigationStackCoordinator, userDiscoveryService: userDiscoveryMock)
            let coordinator = StartChatScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChatWithSearchResults:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([.mockBob, .mockBobby])
            let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
            let coordinator = StartChatScreenCoordinator(parameters: .init(userSession: userSession, navigationStackCoordinator: navigationStackCoordinator, userDiscoveryService: userDiscoveryMock))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsAccountOwner:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockMe, mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetails:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockAlice, mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsIgnoredUser:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsScreenCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockIgnored, mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesWithBadges:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.dropFirst(1).compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId1"] = .init(with: .init(displayName: "First room", inviter: .mockCharlie))
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId2"] = .init(with: .init(displayName: "Second room", inviter: .mockCharlie))
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.inviteSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invites:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId1"] = .init(with: .init(displayName: "First room", inviter: .mockCharlie))
            clientProxy.roomForIdentifierMocks["someAwesomeRoomId2"] = .init(with: .init(displayName: "Second room", inviter: .mockCharlie))
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.inviteSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesNoInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
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
            let coordinator = InviteUsersScreenCoordinator(parameters: .init(selectedUsers: usersSubject.asCurrentValuePublisher(), roomType: roomType, mediaProvider: mediaProvider, userDiscoveryService: userDiscoveryMock))
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
            let mockUserSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
            let createRoomParameters = CreateRoomFlowParameters()
            let selectedUsers: [UserProfileProxy] = [.mockAlice, .mockBob, .mockCharlie]
            let parameters = CreateRoomCoordinatorParameters(userSession: mockUserSession, userIndicatorController: nil, createRoomParameters: .init(createRoomParameters), selectedUsers: .init(selectedUsers))
            let coordinator = CreateRoomCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .createRoomNoUsers:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let mockUserSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
            let createRoomParameters = CreateRoomFlowParameters()
            let parameters = CreateRoomCoordinatorParameters(userSession: mockUserSession, userIndicatorController: nil, createRoomParameters: .init(createRoomParameters), selectedUsers: .init([]))
            let coordinator = CreateRoomCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        }
    }()
}
