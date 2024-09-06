//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol WaitlistScreenViewModelProtocol {
    var actions: AnyPublisher<WaitlistScreenViewModelAction, Never> { get }
    var context: WaitlistScreenViewModelType.Context { get }
    
    /// Set a user session on the screen to transition to the success state.
    func update(userSession: UserSessionProtocol)
}
