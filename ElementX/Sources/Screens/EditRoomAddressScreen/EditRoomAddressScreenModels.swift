//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum EditRoomAddressScreenViewModelAction {
    case dismiss
}

struct EditRoomAddressScreenViewState: BindableState {
    let serverName: String
    var currentAliasLocalPart: String?
    var aliasErrors: Set<EditRoomAddressErrorState> = []
    
    var canSave: Bool {
        currentAliasLocalPart != bindings.desiredAliasLocalPart &&
            aliasErrors.isEmpty &&
            !bindings.desiredAliasLocalPart.isEmpty
    }
    
    var bindings: EditRoomAddressScreenViewStateBindings
}

struct EditRoomAddressScreenViewStateBindings {
    var desiredAliasLocalPart: String
}

enum EditRoomAddressScreenViewAction {
    case save
    case cancel
}
