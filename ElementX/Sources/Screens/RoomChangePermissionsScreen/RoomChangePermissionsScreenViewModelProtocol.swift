//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol RoomChangePermissionsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<RoomChangePermissionsScreenViewModelAction, Never> { get }
    var context: RoomChangePermissionsScreenViewModelType.Context { get }
}
