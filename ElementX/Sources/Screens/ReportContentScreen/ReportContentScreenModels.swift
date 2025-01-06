//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ReportContentScreenViewModelAction: Equatable {
    case cancel
    case submitStarted
    case submitFinished
    case submitFailed(message: String)
}

struct ReportContentScreenViewState: BindableState {
    var bindings: ReportContentScreenViewStateBindings
}

struct ReportContentScreenViewStateBindings {
    var reasonText: String
    var ignoreUser: Bool
}

enum ReportContentScreenViewAction {
    case cancel
    case submit
}
