//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

// TODO: Rebuild as a UI test, unit tests can't interact with the presented screens.
@MainActor
struct OnboardingFlowCoordinatorTests {
    private let sessionSecurityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .unknown, recoveryState: .unknown))
    private let navigationStackCoordinator = NavigationStackCoordinator()
    private let onboardingFlowCoordinator: OnboardingFlowCoordinator
    
    init() {
        let userSession = UserSessionMock(.init())
        userSession.sessionSecurityStatePublisher = sessionSecurityStateSubject.asCurrentValuePublisher()
        
        let flowParameters = CommonFlowParameters(userSession: userSession,
                                                  availableSessionsPublisher: .init([.init(userSession: userSession)]),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  emojiProvider: EmojiProvider(userSettings: userSession.userSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  analytics: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  stateMachineFactory: PublishedStateMachineFactory())
        
        onboardingFlowCoordinator = OnboardingFlowCoordinator(isNewLogin: true,
                                                              appLockService: AppLockServiceMock(),
                                                              navigationStackCoordinator: navigationStackCoordinator,
                                                              flowParameters: flowParameters)
    }
    
    @Test
    func newAccountBecomingVerifiedSkipsIdentityConfirmation() async throws {
        onboardingFlowCoordinator.start()
        #expect(navigationStackCoordinator.rootCoordinator is IdentityConfirmationScreenCoordinator)
        
        let deferred = deferFulfillment(navigationStackCoordinator.observe(\.stackCoordinators.count)) { $0 == 1 }
        sessionSecurityStateSubject.send(.init(verificationState: .verified, recoveryState: .unknown))
        try await deferred.fulfill()
        
        #expect(navigationStackCoordinator.stackCoordinators.last is NotificationPermissionsScreenCoordinator)
    }
}
