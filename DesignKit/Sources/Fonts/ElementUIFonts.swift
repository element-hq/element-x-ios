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
    @available(*, deprecated, message: "Not yet available in compound.")
    @objc static let element = ElementUIFonts(values: ElementBaseFonts())
}

/// ObjC class for holding fonts for use in UIKit.
@objcMembers public class ElementUIFonts: NSObject, Fonts {
    public let largeTitle: UIFont
    public let largeTitleBold: UIFont
    public let title1: UIFont
    public let title1Bold: UIFont
    public let title2: UIFont
    public let title2Bold: UIFont
    public let title3: UIFont
    public let title3Bold: UIFont
    public let headline: UIFont
    public let headlineBold: UIFont
    public let body: UIFont
    public let bodyBold: UIFont
    public let callout: UIFont
    public let calloutBold: UIFont
    public let subheadline: UIFont
    public let subheadlineBold: UIFont
    public let footnote: UIFont
    public let footnoteBold: UIFont
    public let caption1: UIFont
    public let caption1Bold: UIFont
    public let caption2: UIFont
    public let caption2Bold: UIFont
    
    public init(values: ElementBaseFonts) {
        largeTitle = values.largeTitle.uiFont
        largeTitleBold = values.largeTitle.uiFont.bold
        title1 = values.title1.uiFont
        title1Bold = values.title1.uiFont.bold
        title2 = values.title2.uiFont
        title2Bold = values.title2.uiFont.bold
        title3 = values.title3.uiFont
        title3Bold = values.title3.uiFont.bold
        headline = values.headline.uiFont
        headlineBold = values.headline.uiFont.bold
        body = values.body.uiFont
        bodyBold = values.body.uiFont.bold
        callout = values.callout.uiFont
        calloutBold = values.callout.uiFont.bold
        subheadline = values.subheadline.uiFont
        subheadlineBold = values.subheadline.uiFont.bold
        footnote = values.footnote.uiFont
        footnoteBold = values.footnote.uiFont.bold
        caption1 = values.caption1.uiFont
        caption1Bold = values.caption1.uiFont.bold
        caption2 = values.caption2.uiFont
        caption2Bold = values.caption2.uiFont.bold
    }
}
