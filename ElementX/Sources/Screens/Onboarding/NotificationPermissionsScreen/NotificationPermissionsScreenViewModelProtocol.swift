//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol NotificationPermissionsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<NotificationPermissionsScreenViewModelAction, Never> { get }
    var context: NotificationPermissionsScreenViewModelType.Context { get }
}
