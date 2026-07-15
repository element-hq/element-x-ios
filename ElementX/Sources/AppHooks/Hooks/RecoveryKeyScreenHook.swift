//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

@MainActor protocol SecureBackupRecoveryKeyCoordinatorProtocol: CoordinatorProtocol {
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenCoordinatorAction, Never> { get }
}

nonisolated protocol RecoveryKeyScreenHookProtocol: Sendable {
    // periphery:ignore:parameters homeserver - part of the hook signature
    @MainActor func makeCoordinator(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters, homeserver: String) -> any SecureBackupRecoveryKeyCoordinatorProtocol
}

struct DefaultRecoveryKeyScreenHook: RecoveryKeyScreenHookProtocol {
    // periphery:ignore:parameters homeserver - part of the hook signature
    @MainActor func makeCoordinator(parameters: SecureBackupRecoveryKeyScreenCoordinatorParameters, homeserver: String) -> any SecureBackupRecoveryKeyCoordinatorProtocol {
        SecureBackupRecoveryKeyScreenCoordinator(parameters: parameters)
    }
}
