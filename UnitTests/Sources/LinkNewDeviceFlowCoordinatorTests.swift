//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct LinkNewDeviceFlowCoordinatorTests {
    @Test
    func forceLogoutResumesVerificationWithFalse() async throws {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.underlyingIsLoginWithQRCodeSupported = true
        let linkNewDeviceService = LinkNewDeviceServiceMock(.init())
        clientProxy.linkNewDeviceServiceReturnValue = linkNewDeviceService

        let appLockService = AppLockServiceMock.mock()
        appLockService.verifyDeviceOwnerReasonReturnValue = .appLockPINRequired

        let appSettings = AppSettings.volatile()
        let appMediator = AppMediatorMock(.init())
        appMediator.windowManager = WindowManagerMock()

        let flowParameters = CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: appMediator,
                                                  appSettings: appSettings,
                                                  appHooks: AppHooks(),
                                                  analytics: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  notificationManager: NotificationManagerMock(),
                                                  stateMachineFactory: PublishedStateMachineFactory())

        let navigationStackCoordinator = NavigationStackCoordinator()
        let flowCoordinator = LinkNewDeviceFlowCoordinator(navigationStackCoordinator: navigationStackCoordinator,
                                                           appLockService: appLockService,
                                                           flowParameters: flowParameters)
        flowCoordinator.start(animated: false)

        let linkScreenCoordinator = try #require(navigationStackCoordinator.rootCoordinator as? LinkNewDeviceScreenCoordinator)
        let readyStateDeferred = deferFulfillment(linkScreenCoordinator.viewModel.context.observe(\.viewState.mode)) { $0 == .readyToLink(.idle) }
        try await readyStateDeferred.fulfill()

        let appLockScreenDeferred = deferFulfillment(navigationStackCoordinator.observe(\.fullScreenCoverCoordinator)) { $0 != nil }

        linkScreenCoordinator.viewModel.context.send(viewAction: .linkMobileDevice)
        let appLockScreen = try await appLockScreenDeferred.fulfill()
        let appLockScreenCoordinator = try #require(appLockScreen as? AppLockScreenCoordinator)

        let flowActionDeferred = deferFulfillment(flowCoordinator.actionsPublisher) { action in
            if case .forceLogout = action { true } else { false }
        }
        let verificationDeferred = deferFulfillment(linkScreenCoordinator.viewModel.context.observe(\.viewState.mode)) { $0 == .readyToLink(.idle) }

        appLockScreenCoordinator.viewModel.context.send(viewAction: .forgotPIN)
        appLockScreenCoordinator.viewModel.context.alertInfo?.primaryButton.action?()

        try await flowActionDeferred.fulfill()
        try await verificationDeferred.fulfill()
        #expect(linkScreenCoordinator.viewModel.context.viewState.mode == .readyToLink(.idle))
        #expect(!linkNewDeviceService.linkMobileDeviceCalled)
    }
}
