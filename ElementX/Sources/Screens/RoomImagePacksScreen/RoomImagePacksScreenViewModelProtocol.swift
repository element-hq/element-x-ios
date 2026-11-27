//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol RoomImagePacksScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<RoomImagePacksScreenViewModelAction, Never> { get }
    var context: RoomImagePacksScreenViewModelType.Context { get }
}
