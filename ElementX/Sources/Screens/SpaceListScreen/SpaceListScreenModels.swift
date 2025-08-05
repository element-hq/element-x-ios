//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceListScreenViewModelAction {
    case showSettings
}

struct SpaceListScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var rooms: [HomeScreenRoom]
    var joinedRoomsCount: Int
    
    var bindings: SpaceListScreenViewStateBindings
    
    var subtitle: String {
        L10n.screenSpaceListDetails(L10n.commonSpaces(rooms.count), L10n.commonRooms(joinedRoomsCount))
    }
}

struct SpaceListScreenViewStateBindings { }

enum SpaceListScreenViewAction {
    case showSettings
}
