//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceScreenViewModelAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case selectUnjoinedSpace(SpaceRoomProxyProtocol)
    case selectRoom(roomID: String)
}

struct SpaceScreenViewState: BindableState {
    let space: SpaceRoomProxyProtocol
    
    var isPaginating = false
    var rooms: [SpaceRoomProxyProtocol]
    var selectedSpaceRoomID: String?
    var joiningRoomIDs: Set<String> = []
    
    var bindings = SpaceScreenViewStateBindings()
    
    var spaceName: String { space.name ?? L10n.commonSpace }
}

struct SpaceScreenViewStateBindings { }

enum SpaceScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
}
