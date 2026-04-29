//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum BugReportPreflightScreenViewModelAction {
    case copyReport(String)
}

extension BugReportPreflightScreenViewModelAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .copyReport:
            "copyReport"
        }
    }
}

struct BugReportPreflightScreenViewState: BindableState {
    var reportTemplate: String
    var diagnosticsText: String
    var isLoadingDiagnostics = true
    var bindings = BugReportPreflightScreenViewStateBindings()
    
    var fullReport: String {
        """
        \(reportTemplate)

        \(UntranslatedL10n.screenBugReportPreflightDiagnosticsTitle):
        \(diagnosticsText)
        """
    }
}

struct BugReportPreflightScreenViewStateBindings { }

enum BugReportPreflightScreenViewAction {
    case loadDiagnostics
    case cancelDiagnosticsLoading
    case copyReport
}
