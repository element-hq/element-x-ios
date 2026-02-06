//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - BugReportPreflightScreenViewAction

enum BugReportPreflightScreenViewAction {
    case screenAppeared
    case screenDisappeared
    case reportChanged
}

// MARK: - BugReportPreflightScreenViewState

struct BugReportPreflightScreenViewState: BindableState {
    var diagnosticsText: String
    var isDiagnosticsLoading: Bool
    var reportText: String

    var bindings = BugReportPreflightScreenBindings()
}

// MARK: - BugReportPreflightScreenBindings

struct BugReportPreflightScreenBindings {
    var summary = ""
    var steps = ""
    var expected = ""
    var actual = ""
    var isShareSheetPresented = false
}
