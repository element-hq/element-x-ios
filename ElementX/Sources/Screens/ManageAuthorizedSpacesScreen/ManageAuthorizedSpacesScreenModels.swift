//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum ManageAuthorizedSpacesScreenViewModelAction {
    case dismiss
}

struct ManageAuthorizedSpacesScreenViewState: BindableState {
    let authorizedSpacesSelection: AuthorizedSpacesSelection
    var selectedIDs: Set<String>
    
    var hasChanges: Bool {
        authorizedSpacesSelection.initialSelectedIDs != selectedIDs
    }
    
    var isDoneButtonDisabled: Bool {
        selectedIDs.isEmpty || !hasChanges
    }
    
    init(authorizedSpacesSelection: AuthorizedSpacesSelection) {
        self.authorizedSpacesSelection = authorizedSpacesSelection
        selectedIDs = authorizedSpacesSelection.initialSelectedIDs
    }
}

enum ManageAuthorizedSpacesScreenViewAction {
    case cancel
    case done
    case toggle(spaceID: String)
}

struct AuthorizedSpacesSelection {
    let joinedSpaces: [SpaceServiceRoomProtocol]
    let unknownSpacesIDs: [String]
    let initialSelectedIDs: Set<String>
    let selectedIDs: PassthroughSubject<Set<String>, Never> = .init()
}
