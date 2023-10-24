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

import UIKit

/// Text attachment for pills display.
final class PillTextAttachment: NSTextAttachment {
    convenience init?(attachmentData: PillTextAttachmentData) {
        let encoder = JSONEncoder()
        guard let encodedData = try? encoder.encode(attachmentData) else { return nil }
        self.init(data: encodedData, ofType: InfoPlistReader.main.pillsUTType)
        pillData = attachmentData
    }
    
    private(set) var pillData: PillTextAttachmentData!
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        var rect = super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        
        let fontData = pillData.fontData
        // Align the pill text vertically with the surrounding text.
        rect.origin.y = fontData.descender + (fontData.lineHeight - rect.height) / 2.0
        rect.size.width = min(rect.size.width, lineFrag.width)
        return rect
    }
}
