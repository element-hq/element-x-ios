//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// periphery:ignore - required for the architecture
enum DiagnosticsReportScreenViewModelAction { }

struct DiagnosticsReportScreenViewState: BindableState {
    var bindings: DiagnosticsReportScreenViewStateBindings
}

struct DiagnosticsReportScreenViewStateBindings {
    var reportText: String
    var isSharePresented = false
}

enum DiagnosticsReportScreenViewAction {
    case copyToClipboard
    case share
}
