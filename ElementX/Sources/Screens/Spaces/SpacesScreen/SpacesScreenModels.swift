//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpacesScreenViewModelAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case showSettings
    case showCreateSpace
}

struct SpacesScreenViewState: BindableState {
    let userID: String
    var userDisplayName: String?
    var userAvatarURL: URL?
    
    var topLevelSpaces: [SpaceServiceRoom]
    var selectedSpaceID: String?
    
    var isCreateSpaceEnabled: Bool
    
    var bindings: SpacesScreenViewStateBindings
}

struct SpacesScreenViewStateBindings {
    var isPresentingFeatureAnnouncement = false
}

enum SpacesScreenViewAction {
    case spaceAction(SpaceRoomCell.Action)
    case showSettings
    case screenAppeared
    case featureAnnouncementAppeared
    case createSpace
}
