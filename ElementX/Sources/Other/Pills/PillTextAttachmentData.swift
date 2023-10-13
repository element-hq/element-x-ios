//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

enum PillType: Codable, Equatable {
    /// A pill that mentions a user
    case user(userID: String)
    /// A pill that mentions all users in a room
    case allUsers
}

struct EnclosingFontData: Codable, Equatable {
    let descender: CGFloat
    let lineHeight: CGFloat
}

struct PillTextAttachmentData: Codable, Equatable {
    /// Pill type
    let type: PillType
    
    /// Font for the display name
    let fontData: EnclosingFontData
}

extension PillTextAttachmentData {
    init(type: PillType, font: UIFont) {
        self.type = type
        fontData = EnclosingFontData(descender: font.descender, lineHeight: font.lineHeight)
    }
}
