//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

enum RoomSupplementaryFlowCoordinatorAction {
    case finished
}

@MainActor protocol RoomSupplementaryFlowCoordinatorProtocol: FlowCoordinatorProtocol {
    var actionsPublisher: AnyPublisher<RoomSupplementaryFlowCoordinatorAction, Never> { get }
}

nonisolated protocol RoomFlowCoordinatorHookProtocol: Sendable {
    @MainActor func startSupplementaryFlow(flowID: String, navigationStackCoordinator: NavigationStackCoordinator) -> RoomSupplementaryFlowCoordinatorProtocol?
}

struct DefaultRoomFlowCoordinatorHook: RoomFlowCoordinatorHookProtocol {
    @MainActor func startSupplementaryFlow(flowID: String, navigationStackCoordinator: NavigationStackCoordinator) -> RoomSupplementaryFlowCoordinatorProtocol? {
        nil
    }
}
