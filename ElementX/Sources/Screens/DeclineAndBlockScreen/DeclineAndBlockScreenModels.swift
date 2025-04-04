//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DeclineAndBlockScreenViewModelAction {
    case dismiss(hasDeclined: Bool)
}

struct DeclineAndBlockScreenViewState: BindableState {
    var bindings = DeclineAndBlockScreenViewStateBindings()
    
    var isDeclineDisabled: Bool {
        !bindings.shouldBlockUser && !bindings.shouldReport
    }
}

struct DeclineAndBlockScreenViewStateBindings {
    var shouldBlockUser = true
    var shouldReport = false
    var reportReason = ""
}

enum DeclineAndBlockScreenViewAction {
    case decline
    case dismiss
}
