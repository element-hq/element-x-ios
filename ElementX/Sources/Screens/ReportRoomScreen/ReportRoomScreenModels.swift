//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ReportRoomScreenViewModelAction: Equatable {
    case dismiss(shouldLeaveRoom: Bool)
}

struct ReportRoomScreenViewState: BindableState {
    var bindings = ReportRoomScreenViewStateBindings()
    
    var canReport: Bool {
        !bindings.reason.isEmpty
    }
}

struct ReportRoomScreenViewStateBindings {
    var reason = ""
    var shouldLeaveRoom = false
    var alert: AlertInfo<ReportRoomScreenAlertType>?
}

enum ReportRoomScreenViewAction {
    case report
    case dismiss
}

enum ReportRoomScreenAlertType {
    case reportRoomFailed
    case leaveRoomFailed
}
