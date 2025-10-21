//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    
    var bindings = EditRoomAddressScreenViewStateBindings()
}

struct EditRoomAddressScreenViewStateBindings {
    var desiredAliasLocalPart = ""
}

enum EditRoomAddressScreenViewAction {
    case save
    case cancel
}
