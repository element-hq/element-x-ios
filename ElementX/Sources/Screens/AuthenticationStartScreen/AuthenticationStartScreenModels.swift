//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: - Coordinator

enum AuthenticationStartScreenCoordinatorAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
}

enum AuthenticationStartScreenViewModelAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
}

struct AuthenticationStartScreenViewState: BindableState {
    let showCreateAccountButton: Bool
    let isQRCodeLoginEnabled: Bool
    let isBugReportServiceEnabled: Bool
}

enum AuthenticationStartScreenViewAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
}
