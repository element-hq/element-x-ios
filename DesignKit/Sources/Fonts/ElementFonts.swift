//
// Copyright 2022 New Vector Ltd
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

import SwiftUI

public extension Font {
    /// The fonts used by Element as defined in https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0
    static let element = ElementFonts(values: ElementSharedFonts())
}

/// Struct for holding fonts for use in SwiftUI.
public struct ElementFonts: Fonts {
    public let largeTitle: Font
    public let largeTitleB: Font
    public let title1: Font
    public let title1B: Font
    public let title2: Font
    public let title2B: Font
    public let title3: Font
    public let title3SB: Font
    public let headline: Font
    public let subheadline: Font
    public let body: Font
    public let bodySB: Font
    public let callout: Font
    public let calloutSB: Font
    public let footnote: Font
    public let footnoteSB: Font
    public let caption1: Font
    public let caption1SB: Font
    public let caption2: Font
    public let caption2SB: Font
    
    public init(values: ElementSharedFonts) {
        largeTitle = values.largeTitle.font
        largeTitleB = values.largeTitleB.font
        title1 = values.title1.font
        title1B = values.title1B.font
        title2 = values.title2.font
        title2B = values.title2B.font
        title3 = values.title3.font
        title3SB = values.title3SB.font
        headline = values.headline.font
        subheadline = values.subheadline.font
        body = values.body.font
        bodySB = values.bodySB.font
        callout = values.callout.font
        calloutSB = values.calloutSB.font
        footnote = values.footnote.font
        footnoteSB = values.footnoteSB.font
        caption1 = values.caption1.font
        caption1SB = values.caption1SB.font
        caption2 = values.caption2.font
        caption2SB = values.caption2SB.font
    }
}
