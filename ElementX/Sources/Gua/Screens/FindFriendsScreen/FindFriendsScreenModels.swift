//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

enum FindFriendsScreenViewModelAction {
    /// A direct chat with the selected contact is ready; the room id is returned so the
    /// surrounding flow can open it.
    case startedChat(roomID: String)
    case close
}

enum FindFriendsScreenPhase: Equatable {
    case loading
    /// Contacts permission is denied or restricted — show a CTA to open Settings.
    case needsPermission
    /// Discovery ran but none of the user's contacts are on Gua yet.
    case empty
    case loaded
    case error
}

struct FindFriendsScreenViewState: BindableState {
    var phase: FindFriendsScreenPhase = .loading
    var contacts: [DiscoveredContact] = []
    var errorMessage: String?
    var bindings = FindFriendsScreenViewStateBindings()

    /// User id of the contact whose chat is currently being opened (drives a per-row spinner).
    var startingChatUserID: String?
}

struct FindFriendsScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
}

enum FindFriendsScreenViewAction {
    case retry
    case openSystemSettings
    case selectContact(DiscoveredContact)
    case close
}
