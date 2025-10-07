//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceListScreenViewModelAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case showSettings
}

struct SpaceListScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var joinedSpaces: [SpaceRoomProxyProtocol]
    var selectedSpaceID: String?
    
    var bindings: SpaceListScreenViewStateBindings
}

struct SpaceListScreenViewStateBindings {
    var isPresentingFeatureAnnouncement = false
}

enum SpaceListScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
    case showSettings
    case screenAppeared
    case featureAnnouncementAppeared
}
