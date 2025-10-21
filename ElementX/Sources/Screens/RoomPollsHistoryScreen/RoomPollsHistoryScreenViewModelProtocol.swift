//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol RoomPollsHistoryScreenViewModelProtocol {
    var actions: AnyPublisher<RoomPollsHistoryScreenViewModelAction, Never> { get }
    var context: RoomPollsHistoryScreenViewModelType.Context { get }
}
