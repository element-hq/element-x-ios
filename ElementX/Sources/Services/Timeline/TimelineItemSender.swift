//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

nonisolated struct TimelineItemSender: Identifiable, Hashable {
    static let test = TimelineItemSender(id: "@test.matrix.org")
    
    let id: String
    let displayName: String?
    let isDisplayNameAmbiguous: Bool
    let avatarURL: URL?
    let status: UserStatus
    
    init(id: String,
         displayName: String? = nil,
         isDisplayNameAmbiguous: Bool = false,
         avatarURL: URL? = nil,
         status: UserStatus = .init()) {
        self.id = id
        self.displayName = displayName
        self.isDisplayNameAmbiguous = isDisplayNameAmbiguous
        self.avatarURL = avatarURL
        self.status = status
    }
    
    init(senderID: String, senderProfile: ProfileDetails) {
        switch senderProfile {
        case let .ready(displayName, isDisplayNameAmbiguous, avatarURL, status, call):
            self.init(id: senderID,
                      displayName: displayName,
                      isDisplayNameAmbiguous: isDisplayNameAmbiguous,
                      avatarURL: avatarURL.flatMap(URL.init(string:)),
                      status: .init(rustStatus: status, rustCall: call))
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
