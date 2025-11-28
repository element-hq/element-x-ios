//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ManageAuthorizedSpacesScreenViewModelAction {
    case dismiss
}

struct ManageAuthorizedSpacesScreenViewState: BindableState {
    let authorizedSpacesSelection: AuthorizedSpacesSelection
    var desiredSelectedIDs: Set<String>
    
    var hasChanges: Bool {
        authorizedSpacesSelection.selectedIDs != desiredSelectedIDs
    }
    
    var isDoneButtonDisabled: Bool {
        desiredSelectedIDs.isEmpty || !hasChanges
    }
    
    init(authorizedSpacesSelection: AuthorizedSpacesSelection) {
        self.authorizedSpacesSelection = authorizedSpacesSelection
        desiredSelectedIDs = authorizedSpacesSelection.selectedIDs
    }
}

enum ManageAuthorizedSpacesScreenViewAction {
    case cancel
    case done
    case toggle(spaceID: String)
}

struct AuthorizedSpacesSelection {
    let joinedParentSpaces: [SpaceRoomProxyProtocol]
    let unknownSpacesIDs: [String]
    let selectedIDs: Set<String>
}
