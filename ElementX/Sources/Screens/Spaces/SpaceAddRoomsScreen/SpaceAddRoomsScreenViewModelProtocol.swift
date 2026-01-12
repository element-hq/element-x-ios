//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol SpaceAddRoomsScreenViewModelProtocol {
    var actions: AnyPublisher<SpaceAddRoomsScreenViewModelAction, Never> { get }
    var context: SpaceAddRoomsScreenViewModelType.Context { get }
    
    func stop()
}
