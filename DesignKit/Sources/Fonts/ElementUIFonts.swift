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

import UIKit

public extension UIFont {
    /// The fonts used by Element as defined in https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0
    @objc static let element = ElementUIFonts(values: ElementSharedFonts())
}

/// ObjC class for holding fonts for use in UIKit.
@objcMembers public class ElementUIFonts: NSObject, Fonts {
    public let largeTitle: UIFont
    public let largeTitleB: UIFont
    public let title1: UIFont
    public let title1B: UIFont
    public let title2: UIFont
    public let title2B: UIFont
    public let title3: UIFont
    public let title3SB: UIFont
    public let headline: UIFont
    public let subheadline: UIFont
    public let body: UIFont
    public let bodySB: UIFont
    public let callout: UIFont
    public let calloutSB: UIFont
    public let footnote: UIFont
    public let footnoteSB: UIFont
    public let caption1: UIFont
    public let caption1SB: UIFont
    public let caption2: UIFont
    public let caption2SB: UIFont
    
    public init(values: ElementSharedFonts) {
        largeTitle = values.largeTitle.uiFont
        largeTitleB = values.largeTitleB.uiFont
        title1 = values.title1.uiFont
        title1B = values.title1B.uiFont
        title2 = values.title2.uiFont
        title2B = values.title2B.uiFont
        title3 = values.title3.uiFont
        title3SB = values.title3SB.uiFont
        headline = values.headline.uiFont
        subheadline = values.subheadline.uiFont
        body = values.body.uiFont
        bodySB = values.bodySB.uiFont
        callout = values.callout.uiFont
        calloutSB = values.calloutSB.uiFont
        footnote = values.footnote.uiFont
        footnoteSB = values.footnoteSB.uiFont
        caption1 = values.caption1.uiFont
        caption1SB = values.caption1SB.uiFont
        caption2 = values.caption2.uiFont
        caption2SB = values.caption2SB.uiFont
    }
}
