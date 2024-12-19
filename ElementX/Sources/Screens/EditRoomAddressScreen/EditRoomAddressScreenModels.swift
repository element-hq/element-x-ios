//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum EditRoomAddressScreenViewModelAction {
    case done
}

struct EditRoomAddressScreenViewState: BindableState {
    let serverName: String
    var bindings: EditRoomAddressScreenViewStateBindings
}

struct EditRoomAddressScreenViewStateBindings {
    var aliasLocalPart: String
}

enum EditRoomAddressScreenViewAction {
    case done
}
