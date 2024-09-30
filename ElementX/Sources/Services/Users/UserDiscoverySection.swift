//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct UserDiscoverySection {
    let type: UserDiscoverySectionType
    let users: [UserProfileProxy]
    
    var title: String? {
        switch type {
        case .searchResult:
            return nil
        case .suggestions:
            return users.isEmpty ? nil : L10n.commonSuggestions
        }
    }
}

enum UserDiscoverySectionType: Equatable {
    case searchResult
    case suggestions
}
