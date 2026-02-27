//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol LocationSharingScreenViewModelProtocol {
    var actions: AnyPublisher<LocationSharingScreenViewModelAction, Never> { get }
    var context: LocationSharingScreenViewModelType.Context { get }
}
