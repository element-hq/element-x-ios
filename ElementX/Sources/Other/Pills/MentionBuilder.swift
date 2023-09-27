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

extension AttributedStringBuilder: MentionBuilder {
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String) {
        guard mentionsEnabled else {
            attributedString.addAttributes([.MatrixUserID: userID], range: range)
            return
        }
        
        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
        let blockquote = attributes[.MatrixBlockquote]
        
        let attachmentData = PillTextAttachmentData(type: .user(userID: userID), font: font)
        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
            attributedString.addAttributes([.MatrixUserID: userID], range: range)
            return
        }
        
        var attributesToAdd: [NSAttributedString.Key: Any] = [.link: url, .MatrixUserID: userID]
        if let blockquote {
            // mentions can be in blockquotes, so if the replaced string was in on of it we keep the attribute
            attributesToAdd[.MatrixBlockquote] = blockquote
        }
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: attachmentString.length))
        attributedString.replaceCharacters(in: range, with: attachmentString)
    }
}
