//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct OnboardingFlowCoordinatorTests {
    private let sessionSecurityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .unknown, recoveryState: .unknown))
    private let navigationStackCoordinator = NavigationStackCoordinator()
    private let userIndicatorController = UserIndicatorControllerMock()
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
                                                  userIndicatorController: userIndicatorController,
                                                  stateMachineFactory: PublishedStateMachineFactory())
        
        onboardingFlowCoordinator = OnboardingFlowCoordinator(isNewLogin: true,
                                                              appLockService: AppLockServiceMock(),
                                                              navigationStackCoordinator: navigationStackCoordinator,
                                                              flowParameters: flowParameters)
    }
    
    @Test
    func newAccountBecomingVerifiedSkipsIdentityConfirmation() async {
        await start(resolvingTo: .verified)
        #expect(navigationStackCoordinator.rootCoordinator is NotificationPermissionsScreenCoordinator)
    }
    
    @Test
    func newLoginBecomingUnverifiedShowsIdentityConfirmation() async {
        await start(resolvingTo: .unverified)
        #expect(navigationStackCoordinator.rootCoordinator is IdentityConfirmationScreenCoordinator)
    }
    
    // MARK: - Helpers
    
    private func start(resolvingTo verificationState: SessionVerificationState) async {
        let (loadingRetracted, continuation) = AsyncStream<Void>.makeStream()
        userIndicatorController.retractIndicatorWithIdClosure = { _ in continuation.yield() }
        
        onboardingFlowCoordinator.start()
        #expect(navigationStackCoordinator.rootCoordinator == nil)
        #expect(!onboardingFlowCoordinator.shouldStart)
        
        sessionSecurityStateSubject.send(.init(verificationState: verificationState, recoveryState: .unknown))
        var iterator = loadingRetracted.makeAsyncIterator()
        await iterator.next()
    }
}
