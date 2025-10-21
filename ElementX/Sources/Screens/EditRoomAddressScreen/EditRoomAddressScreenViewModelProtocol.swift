//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol EditRoomAddressScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<EditRoomAddressScreenViewModelAction, Never> { get }
    var context: EditRoomAddressScreenViewModelType.Context { get }
}
