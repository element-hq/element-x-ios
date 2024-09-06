//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

@MainActor
protocol UserProfileScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<UserProfileScreenViewModelAction, Never> { get }
    var context: UserProfileScreenViewModelType.Context { get }
    
    func stop()
}
