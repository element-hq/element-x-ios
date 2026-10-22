//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct OnboardingFlowCoordinatorTests {
    private let securityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .unknown, recoveryState: .unknown))
    private let userSettings = UserSettings.mock()
    private var onboardingFlowCoordinator: OnboardingFlowCoordinator!
    
    init() {
        // Leaves the identity confirmation as the only step that onboarding might need.
        userSettings.app.hasRunNotificationPermissionsOnboarding = true
    }
    
    @Test
    mutating func identityConfirmationIsSkippedWhenVerified() {
        securityStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        setUpCoordinator()
        
        #expect(!onboardingFlowCoordinator.shouldStart)
    }
    
    @Test
    mutating func identityConfirmationIsNeededWhenUnverified() {
        userSettings.account.hasRunIdentityConfirmationOnboarding = true
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .enabled))
        setUpCoordinator()
        
        #expect(onboardingFlowCoordinator.shouldStart)
    }
    
    @Test
    mutating func identityConfirmationIsNeededUntilTheStateIsKnown() {
        setUpCoordinator()
        
        #expect(onboardingFlowCoordinator.shouldStart)
    }
    
    @Test
    mutating func identityConfirmationIsMarkedAsRunOnceVerified() async {
        setUpCoordinator()
        
        securityStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        await waitForMainQueue()
        
        #expect(userSettings.account.hasRunIdentityConfirmationOnboarding)
    }
    
    // MARK: - Private
    
    private mutating func setUpCoordinator() {
        let userSession = UserSessionMock(.init(userSettings: userSettings))
        userSession.sessionSecurityStatePublisher = securityStateSubject.asCurrentValuePublisher()
        
        let flowParameters = CommonFlowParameters(userSession: userSession,
                                                  availableSessionsPublisher: .init([.init(userSession: userSession)]),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  emojiProvider: EmojiProvider(userSettings: userSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  analytics: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  stateMachineFactory: PublishedStateMachineFactory())
        
        onboardingFlowCoordinator = OnboardingFlowCoordinator(isNewLogin: false,
                                                              appLockService: AppLockServiceMock(),
                                                              navigationStackCoordinator: NavigationStackCoordinator(),
                                                              flowParameters: flowParameters)
    }
    
    /// The coordinator receives verification state changes on the main queue.
    private func waitForMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
