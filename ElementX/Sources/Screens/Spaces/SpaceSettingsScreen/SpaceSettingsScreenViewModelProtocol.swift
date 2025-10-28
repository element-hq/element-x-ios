//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol SpaceSettingsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<SpaceSettingsScreenViewModelAction, Never> { get }
    var context: SpaceSettingsScreenViewModelType.Context { get }
}
