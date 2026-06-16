//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine

@MainActor
protocol FindFriendsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<FindFriendsScreenViewModelAction, Never> { get }
    var context: FindFriendsScreenViewModelType.Context { get }
}
