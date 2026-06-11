//
// Copyright 2025 Gua-ra <https://github.com/Gua-ra>
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//
// ============================================================
// GUA FORK — This file does not exist in the upstream project.
// It will never cause merge conflicts when pulling upstream
// updates. Gua-specific extensions to SettingsFlowCoordinator
// live here to keep upstream file diffs minimal.
// ============================================================

import Combine

// MARK: - Gua: Two-step verification

extension SettingsFlowCoordinator {
    /// Presents the Gua two-step verification screen (PIN setup / change).
    ///
    /// Called from `handleAppRoute(.settingsTwoStepVerification)` and from the
    /// settings screen's `.twoStepVerification` action.
    func presentTwoStepVerification() {
        guard let identityServiceClient = IdentityServiceClient() else {
            MXLog.warning("Identity service is not configured; cannot show two-step verification screen.")
            return
        }
        let parameters = TwoStepVerificationScreenCoordinatorParameters(clientProxy: flowParameters.userSession.clientProxy,
                                                                        identityServiceClient: identityServiceClient,
                                                                        userIndicatorController: flowParameters.userIndicatorController)
        let coordinator = TwoStepVerificationScreenCoordinator(parameters: parameters)

        coordinator.actionsPublisher
            .sink { _ in }
            .store(in: &cancellables)

        navigationStackCoordinator.push(coordinator)
    }
}
