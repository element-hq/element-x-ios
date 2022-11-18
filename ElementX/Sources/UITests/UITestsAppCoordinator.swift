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
    private var currentRootCoordinator: CoordinatorProtocol?
    private let navigationStackCoordinator: NavigationStackCoordinator
    let notificationManager: NotificationManagerProtocol? = nil
    
    init() {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        ServiceLocator.shared.register(userNotificationController: MockUserNotificationController())
    }
    
    func start() {
        let screens = mockScreens()
        let rootCoordinator = UITestsRootCoordinator(mockScreens: screens) { id in
            guard let screen = screens.first(where: { $0.id == id }) else {
                fatalError()
            }
            
            // Store the initial coordinator so that it stays alive if drops it
            // For example when replacing the root in the authentication flows
            self.currentRootCoordinator = screen.coordinator
            
            self.navigationStackCoordinator.setRootCoordinator(screen.coordinator)
        }
        
        navigationStackCoordinator.setRootCoordinator(rootCoordinator)
        
        Bundle.elementFallbackLanguage = "en"
    }
        
    func toPresentable() -> AnyView {
        navigationStackCoordinator.toPresentable()
    }
    
    private func mockScreens() -> [MockScreen] {
        UITestScreenIdentifier.allCases.map { MockScreen(id: $0, navigationStackCoordinator: navigationStackCoordinator) }
    }
}

@MainActor
class MockScreen: Identifiable {
    let id: UITestScreenIdentifier
    let navigationStackCoordinator: NavigationStackCoordinator
    lazy var coordinator: CoordinatorProtocol = {
        switch id {
        case .login:
            return LoginCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                      navigationStackCoordinator: navigationStackCoordinator))
        case .serverSelection:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                userNotificationController: MockUserNotificationController(),
                                                                isModallyPresented: true))
        case .serverSelectionNonModal:
            return ServerSelectionCoordinator(parameters: .init(authenticationService: MockAuthenticationServiceProxy(),
                                                                userNotificationController: MockUserNotificationController(),
                                                                isModallyPresented: false))
        case .analyticsPrompt:
            return AnalyticsPromptCoordinator(parameters: .init(userSession: MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@mock:client.com"),
                                                                                             mediaProvider: MockMediaProvider())))
        case .authenticationFlow:
            return AuthenticationCoordinator(authenticationService: MockAuthenticationServiceProxy(),
                                             navigationStackCoordinator: navigationStackCoordinator)
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
            let session = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@mock:matrix.org"),
                                          mediaProvider: MockMediaProvider())
            return HomeScreenCoordinator(parameters: .init(userSession: session,
                                                           attributedStringBuilder: AttributedStringBuilder(),
                                                           bugReportService: MockBugReportService(),
                                                           navigationStackCoordinator: navigationStackCoordinator))
        case .settings:
            return SettingsCoordinator(parameters: .init(navigationStackCoordinator: navigationStackCoordinator,
                                                         userNotificationController: MockUserNotificationController(),
                                                         userSession: MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@mock:client.com"),
                                                                                      mediaProvider: MockMediaProvider()),
                                                         bugReportService: MockBugReportService()))
        case .bugReport:
            return BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                          userNotificationController: MockUserNotificationController(),
                                                          screenshot: nil,
                                                          isModallyPresented: false))
        case .bugReportWithScreenshot:
            return BugReportCoordinator(parameters: .init(bugReportService: MockBugReportService(),
                                                          userNotificationController: MockUserNotificationController(),
                                                          screenshot: Asset.Images.appLogo.image,
                                                          isModallyPresented: false))
        case .onboarding:
            return OnboardingCoordinator()
        case .roomPlainNoAvatar:
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             roomName: "Some room name",
                                                             roomAvatarUrl: nil,
                                                             emojiProvider: EmojiProvider())
            return RoomScreenCoordinator(parameters: parameters)
        case .roomEncryptedWithAvatar:
            let parameters = RoomScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                             timelineController: MockRoomTimelineController(),
                                                             mediaProvider: MockMediaProvider(),
                                                             roomName: "Some room name",
                                                             roomAvatarUrl: "mock_url",
                                                             emojiProvider: EmojiProvider())
            return RoomScreenCoordinator(parameters: parameters)
        case .sessionVerification:
            let parameters = SessionVerificationCoordinatorParameters(sessionVerificationControllerProxy: MockSessionVerificationControllerProxy())
            return SessionVerificationCoordinator(parameters: parameters)
        }
    }()
    
    init(id: UITestScreenIdentifier, navigationStackCoordinator: NavigationStackCoordinator) {
        self.id = id
        self.navigationStackCoordinator = navigationStackCoordinator
    }
}
