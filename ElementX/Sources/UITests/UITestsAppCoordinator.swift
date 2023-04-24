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
    private var mockScreen: MockScreen?
    let notificationManager: NotificationManagerProtocol = NotificationManagerMock()
    
    init() {
        UIView.setAnimationsEnabled(false)
        navigationRootCoordinator = NavigationRootCoordinator()
        
        ServiceLocator.shared.register(userIndicatorController: MockUserIndicatorController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.uitests")
        AppSettings.reset()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock())
        ServiceLocator.shared.register(analytics: Analytics(client: AnalyticsClientMock()))
    }
    
    func start() {
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
    
    init(id: UITestsScreenIdentifier) {
        self.id = id
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
                                                                           userIndicatorController: MockUserIndicatorController(),
                                                                           isModallyPresented: true))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .serverSelectionNonModal:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                userIndicatorController: MockUserIndicatorController(),
                                                                isModallyPresented: false))
        case .analyticsPrompt:
            return AnalyticsPromptScreenCoordinator()
        case .analyticsSettingsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = AnalyticsSettingsScreenCoordinator()
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
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
                                                                      bugReportService: BugReportServiceMock(),
                                                                      navigationStackCoordinator: navigationStackCoordinator))
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
        case .onboarding:
            return OnboardingCoordinator()
        case .roomPlainNoAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: nil)),
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomEncryptedWithAvatar:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Some room name", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "New room", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Small timeline, paginating", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
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
                                                             roomProxy: RoomProxyMock(with: .init(displayName: "Large timeline", avatarURL: URL.picturesDirectory)),
                                                             timelineController: timelineController,
                                                             mediaProvider: MockMediaProvider(),
                                                             emojiProvider: EmojiProvider())
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .sessionVerification:
            var sessionVerificationControllerProxy = SessionVerificationControllerProxyMock.configureMock(requestDelay: .seconds(2))
            let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationControllerProxy)
            return SessionVerificationScreenCoordinator(parameters: parameters)
        case .userSessionScreen:
            let navigationSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: SplashScreenCoordinator())
            
            let clientProxy = MockClientProxy(userID: "@mock:client.com", roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms)))
            
            let coordinator = UserSessionFlowCoordinator(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider()),
                                                         navigationSplitCoordinator: navigationSplitCoordinator,
                                                         bugReportService: BugReportServiceMock(),
                                                         roomTimelineControllerFactory: MockRoomTimelineControllerFactory())
            
            coordinator.start()
            
            retainedState.append(coordinator)
            
            return navigationSplitCoordinator
        case .roomDetailsScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockCharlie]
            let roomProxy = RoomProxyMock(with: .init(id: "MockRoomIdentifier",
                                                      displayName: "Room",
                                                      isEncrypted: true,
                                                      members: members))
            let coordinator = RoomDetailsCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                       roomProxy: roomProxy,
                                                                       mediaProvider: MockMediaProvider()))
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
                                                      members: members))
            let coordinator = RoomDetailsCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                       roomProxy: roomProxy,
                                                                       mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMembersListScreen:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockCharlie]
            let coordinator = RoomMembersListCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                           mediaProvider: MockMediaProvider(),
                                                                           members: members))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .reportContent:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = ReportContentCoordinator(parameters: .init(itemID: "test",
                                                                         senderID: RoomMemberProxyMock.mockAlice.userID,
                                                                         roomProxy: RoomProxyMock(with: .init(displayName: "test"))))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChat:
            ServiceLocator.shared.settings.startChatUserSuggestionsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([.mockAlice, .mockBob, .mockCharlie])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([])
            let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"), mediaProvider: MockMediaProvider())
            let parameters: StartChatCoordinatorParameters = .init(userSession: userSession, navigationStackCoordinator: navigationStackCoordinator, userDiscoveryService: userDiscoveryMock)
            let coordinator = StartChatCoordinator(parameters: parameters)
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .startChatWithSearchResults:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([.mockBob, .mockBobby])
            let userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
            let coordinator = StartChatCoordinator(parameters: .init(userSession: userSession, navigationStackCoordinator: navigationStackCoordinator, userDiscoveryService: userDiscoveryMock))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsAccountOwner:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockMe, mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetails:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockAlice, mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .roomMemberDetailsIgnoredUser:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let coordinator = RoomMemberDetailsCoordinator(parameters: .init(roomMemberProxy: RoomMemberProxyMock.mockIgnored, mediaProvider: MockMediaProvider()))
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
                                                      members: members))
            let coordinator = RoomDetailsCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                                       roomProxy: roomProxy,
                                                                       mediaProvider: MockMediaProvider()))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesWithBadges:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.dropFirst(1).compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomInviter = RoomMemberProxyMock.mockCharlie
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.visibleRoomsSummaryProvider = summaryProvider
            clientProxy.invitesSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invites:
            ServiceLocator.shared.settings.seenInvites = Set([RoomSummary].mockInvites.compactMap(\.id))
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            clientProxy.roomInviter = RoomMemberProxyMock.mockCharlie
            let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
            clientProxy.visibleRoomsSummaryProvider = summaryProvider
            clientProxy.invitesSummaryProvider = summaryProvider
            
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .invitesNoInvites:
            let navigationStackCoordinator = NavigationStackCoordinator()
            let clientProxy = MockClientProxy(userID: "@mock:client.com")
            let coordinator = InvitesScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        case .inviteUsers:
            ServiceLocator.shared.settings.startChatUserSuggestionsEnabled = true
            let navigationStackCoordinator = NavigationStackCoordinator()
            let userDiscoveryMock = UserDiscoveryServiceMock()
            userDiscoveryMock.fetchSuggestionsReturnValue = .success([.mockAlice, .mockBob, .mockCharlie])
            userDiscoveryMock.searchProfilesWithReturnValue = .success([])
            let coordinator = InviteUsersScreenCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@mock:client.com"), mediaProvider: MockMediaProvider()), userDiscoveryService: userDiscoveryMock))
            navigationStackCoordinator.setRootCoordinator(coordinator)
            return navigationStackCoordinator
        }
    }()
}
