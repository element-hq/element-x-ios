//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

struct TimelineItemSender: Identifiable, Hashable {
    static let test = TimelineItemSender(id: "@test.matrix.org")
    
    let id: String
    let displayName: String?
    let isDisplayNameAmbiguous: Bool
    let avatarURL: URL?
    
    init(id: String, displayName: String? = nil, isDisplayNameAmbiguous: Bool = false, avatarURL: URL? = nil) {
        self.id = id
        // Tchap : if `displayName` is nil, calculate it from userId.
//        self.displayName = displayName
        self.displayName = displayName ?? MatrixIdFromString(id).userDisplayName?.displayName
        self.isDisplayNameAmbiguous = isDisplayNameAmbiguous
        self.avatarURL = avatarURL
    }
        
    var disambiguatedDisplayName: String? {
        guard let displayName else {
            return nil
        }
        
        return isDisplayNameAmbiguous ? "\(displayName) (\(id))" : displayName
    }
}
