//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DialPadScreenViewModelAction {
    case createdRoom(JoinedRoomProxyProtocol)
    case close
}

struct DialPadScreenViewState: BindableState {
    var bindings = DialPadScreenViewStateBindings()
}

struct DialPadScreenViewStateBindings {
    var phoneNumber = ""
    var alertInfo: AlertInfo<DialPadScreenErrorType>?
}

enum DialPadScreenViewAction {
    case digit(String)
    case delete
    case dial
    case close
}

enum DialPadScreenErrorType: Error {
    case failedCreatingRoom
    case unknown
}
