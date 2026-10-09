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
    @Test(arguments: [EncryptionResetScreenVariant.hasConfirmationOptions, .noOptionsWithEncryptedChats, .noOptionsWithoutEncryptedChats])
    func startPresentsTheResetScreen(variant: EncryptionResetScreenVariant) {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let coordinator = makeCoordinator(variant: variant, navigationStackCoordinator: navigationStackCoordinator)
        
        coordinator.start(animated: false)
        
        #expect(navigationStackCoordinator.rootCoordinator is EncryptionResetScreenCoordinator)
    }
    
    @Test
    func defaultVariantHasConfirmationOptions() {
        let parameters = EncryptionResetFlowCoordinatorParameters(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                                  appMediator: AppMediatorMock(.init()),
                                                                  appHooks: AppHooks(),
                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                  navigationStackCoordinator: NavigationStackCoordinator(),
                                                                  windowManger: WindowManagerMock())
        
        #expect(parameters.variant == .hasConfirmationOptions)
    }
    
    // MARK: - Helpers
    
    private func makeCoordinator(variant: EncryptionResetScreenVariant,
                                 navigationStackCoordinator: NavigationStackCoordinator) -> EncryptionResetFlowCoordinator {
        EncryptionResetFlowCoordinator(parameters: .init(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                         appMediator: AppMediatorMock(.init()),
                                                         appHooks: AppHooks(),
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                         windowManger: WindowManagerMock(),
                                                         variant: variant))
    }
}
