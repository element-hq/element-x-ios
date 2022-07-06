//
// Copyright 2021 New Vector Ltd
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

/// Fonts at  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0
@objcMembers
public class ElementSharedFonts {
    // MARK: - Types
    
    /// A wrapper to provide both a `UIFont` and a SwiftUI `Font` in the same type.
    /// The need for this comes from `Font` not adapting for dynamic type until the app
    /// is restarted (or working at all in Xcode Previews) when initialised from a `UIFont`
    /// (even if that font was created with the appropriate metrics).
    public struct SharedFont {
        public let uiFont: UIFont
        public let font: Font
    }
    
    // MARK: - Private
    
    /// Returns an instance of the font associated with the text style and scaled appropriately for the content size category defined in the trait collection.
    /// Keep this method private method at the moment and create a DesignKit.Fonts.TextStyle if needed.
    private func font(forTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection)
    }
}

// MARK: - Fonts protocol

public extension ElementSharedFonts {
    var largeTitle: SharedFont {
        let uiFont = font(forTextStyle: .largeTitle)
        return SharedFont(uiFont: uiFont, font: .largeTitle)
    }
    
    var largeTitleB: SharedFont {
        let uiFont = largeTitle.uiFont.bold
        return SharedFont(uiFont: uiFont, font: .largeTitle.bold())
    }
            
    var title1: SharedFont {
        let uiFont = font(forTextStyle: .title1)
        return SharedFont(uiFont: uiFont, font: .title)
    }
    
    var title1B: SharedFont {
        let uiFont = title1.uiFont.bold
        return SharedFont(uiFont: uiFont, font: .title.bold())
    }
    
    var title2: SharedFont {
        let uiFont = font(forTextStyle: .title2)
        return SharedFont(uiFont: uiFont, font: .title2)
    }
    
    var title2B: SharedFont {
        let uiFont = title2.uiFont.bold
        return SharedFont(uiFont: uiFont, font: .title2.bold())
    }
    
    var title3: SharedFont {
        let uiFont = font(forTextStyle: .title3)
        return SharedFont(uiFont: uiFont, font: .title3)
    }
    
    var title3SB: SharedFont {
        let uiFont = title3.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .title3.weight(.semibold))
    }
    
    var headline: SharedFont {
        let uiFont = font(forTextStyle: .headline)
        return SharedFont(uiFont: uiFont, font: .headline)
    }
    
    var subheadline: SharedFont {
        let uiFont = font(forTextStyle: .subheadline)
        return SharedFont(uiFont: uiFont, font: .subheadline)
    }
    
    var body: SharedFont {
        let uiFont = font(forTextStyle: .body)
        return SharedFont(uiFont: uiFont, font: .body)
    }
    
    var bodySB: SharedFont {
        let uiFont = body.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .body.weight(.semibold))
    }
    
    var callout: SharedFont {
        let uiFont = font(forTextStyle: .callout)
        return SharedFont(uiFont: uiFont, font: .callout)
    }
    
    var calloutSB: SharedFont {
        let uiFont = callout.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .callout.weight(.semibold))
    }
    
    var footnote: SharedFont {
        let uiFont = font(forTextStyle: .footnote)
        return SharedFont(uiFont: uiFont, font: .footnote)
    }
    
    var footnoteSB: SharedFont {
        let uiFont = footnote.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .footnote.weight(.semibold))
    }
    
    var caption1: SharedFont {
        let uiFont = font(forTextStyle: .caption1)
        return SharedFont(uiFont: uiFont, font: .caption)
    }
    
    var caption1SB: SharedFont {
        let uiFont = caption1.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .caption.weight(.semibold))
    }
    
    var caption2: SharedFont {
        let uiFont = font(forTextStyle: .caption2)
        return SharedFont(uiFont: uiFont, font: .caption2)
    }
    
    var caption2SB: SharedFont {
        let uiFont = caption2.uiFont.semiBold
        return SharedFont(uiFont: uiFont, font: .caption2.weight(.semibold))
    }
}
