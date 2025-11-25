//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

struct TimelineItemSender: Identifiable, Hashable {
    static let test = TimelineItemSender(id: "@test.matrix.org")
    
    let id: String
    let displayName: String?
    let isDisplayNameAmbiguous: Bool
    let avatarURL: URL?
    
    init(id: String, displayName: String? = nil, isDisplayNameAmbiguous: Bool = false, avatarURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.isDisplayNameAmbiguous = isDisplayNameAmbiguous
        self.avatarURL = avatarURL
    }
    
    init(senderID: String, senderProfile: ProfileDetails) {
        switch senderProfile {
        case let .ready(displayName, isDisplayNameAmbiguous, avatarUrl):
            self.init(id: senderID,
                      displayName: displayName,
                      isDisplayNameAmbiguous: isDisplayNameAmbiguous,
                      avatarURL: avatarUrl.flatMap(URL.init(string:)))
        default:
            self.init(id: senderID,
                      displayName: nil,
                      isDisplayNameAmbiguous: false,
                      avatarURL: nil)
        }
    }
        
    var disambiguatedDisplayName: String? {
        guard let displayName else {
            return nil
        }
        
        return isDisplayNameAmbiguous ? "\(displayName) (\(id))" : displayName
    }
}
