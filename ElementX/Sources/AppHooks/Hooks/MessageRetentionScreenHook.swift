//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

struct RoomDetailsMessageRetentionScreenCoordinatorParameters { }

enum RoomDetailsMessageRetentionScreenCoordinatorAction {
    case done
}

@MainActor protocol RoomDetailsMessageRetentionCoordinatorProtocol: CoordinatorProtocol {
    var actionsPublisher: AnyPublisher<RoomDetailsMessageRetentionScreenCoordinatorAction, Never> { get }
}

nonisolated protocol MessageRetentionScreenHookProtocol: Sendable {
    /// Returns a coordinator for the message retention screen, or nil if the feature is unavailable in this build.
    @MainActor func makeCoordinator(parameters: RoomDetailsMessageRetentionScreenCoordinatorParameters) -> (any RoomDetailsMessageRetentionCoordinatorProtocol)?
}

struct DefaultMessageRetentionScreenHook: MessageRetentionScreenHookProtocol {
    @MainActor func makeCoordinator(parameters: RoomDetailsMessageRetentionScreenCoordinatorParameters) -> (any RoomDetailsMessageRetentionCoordinatorProtocol)? {
        nil
    }
}
