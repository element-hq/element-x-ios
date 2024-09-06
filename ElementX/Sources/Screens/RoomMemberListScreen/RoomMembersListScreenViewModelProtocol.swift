//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol RoomMembersListScreenViewModelProtocol {
    var actions: AnyPublisher<RoomMembersListScreenViewModelAction, Never> { get }
    var context: RoomMembersListScreenViewModelType.Context { get }
    
    func stop()
}
