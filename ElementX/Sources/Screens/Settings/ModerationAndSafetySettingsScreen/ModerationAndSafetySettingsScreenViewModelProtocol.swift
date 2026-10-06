//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

protocol ModerationAndSafetySettingsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<ModerationAndSafetySettingsScreenViewModelAction, Never> { get }
    var context: ModerationAndSafetySettingsScreenViewModelType.Context { get }
}
