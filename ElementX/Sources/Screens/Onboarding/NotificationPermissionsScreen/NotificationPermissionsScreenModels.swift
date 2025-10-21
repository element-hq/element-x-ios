//
// Copyright 2025 Element Creations Ltd.
// Copyright 2021-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum NotificationPermissionsScreenViewAction {
    case enable
    case notNow
}

enum NotificationPermissionsScreenViewModelAction {
    case done
}

struct NotificationPermissionsScreenViewState: BindableState { }
