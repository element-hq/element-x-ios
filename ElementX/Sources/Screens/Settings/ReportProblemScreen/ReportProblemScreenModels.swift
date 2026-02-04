//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ReportProblemScreenViewModelAction {
    case dismiss
}

struct ReportProblemScreenViewState: BindableState {
    let diagnosticInfo: String
    var reportTextForSharing = ""
    var bindings = ReportProblemScreenViewStateBindings()
}

struct ReportProblemScreenViewStateBindings {
    var problemDescription = ""
    var showShareSheet = false
}

enum ReportProblemScreenViewAction {
    case copyToClipboard
    case share
}
