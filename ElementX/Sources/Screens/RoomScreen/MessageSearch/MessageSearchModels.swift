//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum MessageSearchViewModelAction: Equatable {
    case selectMessage(eventID: String)
    case dismiss
}

enum MessageSearchViewAction {
    case searchQueryChanged(String)
    case clearSearch
    case selectMessage(eventID: String)
    case dismiss
}

struct MessageSearchViewState: BindableState {
    var searchResults: [MessageSearchResult] = []
    var isLoading = false
    var hasSearched = false
    
    var bindings = MessageSearchViewStateBindings()
}

struct MessageSearchViewStateBindings {
    var searchQuery = ""
}

struct MessageSearchResult: Identifiable, Equatable {
    let id: String
    let eventID: String
    let sender: String
    let content: String
    let timestamp: Date
    let roomID: String
}
