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
    static let element = ElementFonts(values: ElementBaseFonts())
}

/// Struct for holding fonts for use in SwiftUI.
public struct ElementFonts: Fonts {
    public let largeTitle: Font
    public let largeTitleBold: Font
    public let title1: Font
    public let title1Bold: Font
    public let title2: Font
    public let title2Bold: Font
    public let title3: Font
    public let title3Bold: Font
    public let headline: Font
    public let headlineBold: Font
    public let body: Font
    public let bodyBold: Font
    public let callout: Font
    public let calloutBold: Font
    public let subheadline: Font
    public let subheadlineBold: Font
    public let footnote: Font
    public let footnoteBold: Font
    public let caption1: Font
    public let caption1Bold: Font
    public let caption2: Font
    public let caption2Bold: Font
    
    public init(values: ElementBaseFonts) {
        largeTitle = values.largeTitle.font
        largeTitleBold = values.largeTitle.font.bold()
        title1 = values.title1.font
        title1Bold = values.title1.font.bold()
        title2 = values.title2.font
        title2Bold = values.title2.font.bold()
        title3 = values.title3.font
        title3Bold = values.title3.font.bold()
        headline = values.headline.font
        headlineBold = values.headline.font.bold()
        body = values.body.font
        bodyBold = values.body.font.bold()
        callout = values.callout.font
        calloutBold = values.callout.font.bold()
        subheadline = values.subheadline.font
        subheadlineBold = values.subheadline.font.bold()
        footnote = values.footnote.font
        footnoteBold = values.footnote.font.bold()
        caption1 = values.caption1.font
        caption1Bold = values.caption1.font.bold()
        caption2 = values.caption2.font
        caption2Bold = values.caption2.font.bold()
    }
}
