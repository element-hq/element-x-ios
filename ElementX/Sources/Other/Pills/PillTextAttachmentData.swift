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

enum PillType: Codable {
    /// A pill that mentions a user
    case user(userID: String)
}

struct PillTextAttachmentData {
    // MARK: - Properties

    /// Pill type
    let type: PillType

    /// Font for the display name
    let font: UIFont
}

extension PillTextAttachmentData: Codable {
    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type
        case font
    }
    
    enum PillTextAttachmentDataError: Error {
        case noFontData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PillType.self, forKey: .type)
        let fontData = try container.decode(Data.self, forKey: .font)
        if let font = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFont.self, from: fontData) {
            self.font = font
        } else {
            throw PillTextAttachmentDataError.noFontData
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        let fontData = try NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
        try container.encode(fontData, forKey: .font)
    }
}
