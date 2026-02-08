//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct BugReportPreflightScreenViewState: BindableState {
    var diagnosticsText: String?
    var isLoadingDiagnostics: Bool
    var shareText: String?
    var bindings: BugReportPreflightScreenViewStateBindings
}

struct BugReportPreflightScreenViewStateBindings {
    var summary: String
    var stepsToReproduce: String
    var expectedResult: String
    var actualResult: String
}

enum BugReportPreflightScreenViewAction {
    case copyToClipboard
    case share
    case dismissShare
}
