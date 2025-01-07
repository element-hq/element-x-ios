//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol RoomDirectorySearchScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<RoomDirectorySearchScreenViewModelAction, Never> { get }
    var context: RoomDirectorySearchScreenViewModelType.Context { get }
}
