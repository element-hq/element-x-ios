//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DeclineAndBlockScreenViewModelAction: Equatable {
    case dismiss(hasDeclined: Bool)
}

struct DeclineAndBlockScreenViewState: BindableState {
    var bindings = DeclineAndBlockScreenViewStateBindings()
    
    var isDeclineDisabled: Bool {
        if bindings.shouldReport {
            return bindings.reportReason.isEmpty
        }
        return !bindings.shouldBlockUser && !bindings.shouldReport
    }
}

struct DeclineAndBlockScreenViewStateBindings {
    var shouldBlockUser = true
    var shouldReport = false
    var reportReason = ""
    
    var alert: AlertInfo<DeclineAndBlockAlertType>?
}

enum DeclineAndBlockScreenViewAction {
    case decline
    case dismiss
}

enum DeclineAndBlockAlertType {
    case declineFailed
}
