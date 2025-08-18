//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol SpaceListScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<SpaceListScreenViewModelAction, Never> { get }
    var context: SpaceListScreenViewModelType.Context { get }
}
