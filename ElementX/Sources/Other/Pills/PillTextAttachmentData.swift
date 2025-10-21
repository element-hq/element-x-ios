//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

enum PillType: Codable, Equatable {
    enum EventRoom: Codable, Equatable {
        case roomAlias(String)
        case roomID(String)
    }
    
    case event(room: EventRoom)
    case roomAlias(String)
    case roomID(String)
    /// A pill that mentions a user
    case user(userID: String)
    /// A pill that mentions all users in a room
    case allUsers
}

struct PillTextAttachmentData: Codable, Equatable {
    struct Font: Codable, Equatable {
        let descender: CGFloat
        let lineHeight: CGFloat
    }
    
    /// Pill type
    let type: PillType
    
    /// Font for the display name
    let fontData: Font
}

extension PillTextAttachmentData {
    init(type: PillType, font: UIFont) {
        self.type = type
        fontData = Font(descender: font.descender, lineHeight: font.lineHeight)
    }
}
