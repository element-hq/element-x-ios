//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct EncryptionResetFlowCoordinatorTests {
    @Test(arguments: [EncryptionResetScreenMode.hasConfirmationOptions, .noOptionsWithEncryptedChats, .noOptionsWithoutEncryptedChats])
    func startPresentsTheResetScreen(mode: EncryptionResetScreenMode) {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = makeCoordinator(mode: mode, navigationStackCoordinator: navigationStackCoordinator)
        
        coordinator.start(animated: false)
        
        #expect(navigationStackCoordinator.rootCoordinator is EncryptionResetScreenCoordinator)
    }
    
    @Test
    func defaultModeHasConfirmationOptions() {
        let parameters = EncryptionResetFlowCoordinatorParameters(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                                  appMediator: AppMediatorMock(.init()),
                                                                  appHooks: AppHooks(),
                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                  navigationStackCoordinator: NavigationStackCoordinator(),
                                                                  windowManger: WindowManagerMock())
        
        #expect(parameters.mode == .hasConfirmationOptions)
    }
    
    // MARK: - Helpers
    
    private func makeCoordinator(mode: EncryptionResetScreenMode,
                                 navigationStackCoordinator: NavigationStackCoordinator) -> EncryptionResetFlowCoordinator {
        EncryptionResetFlowCoordinator(parameters: .init(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                         appMediator: AppMediatorMock(.init()),
                                                         appHooks: AppHooks(),
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                         windowManger: WindowManagerMock(),
                                                         mode: mode))
    }
}
