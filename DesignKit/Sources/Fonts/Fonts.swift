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

import Foundation

/// Describe fonts used in the application.
/// Font names are based on Element typography  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0 which is based on Apple font text styles (UIFont.TextStyle): https://developer.apple.com/documentation/uikit/uifonttextstyle
/// Create a custom TextStyle enum (like DesignKit.Fonts.TextStyle) is also a possibility
public protocol Fonts {
    associatedtype FontType
    
    /// The font for large titles.
    var largeTitle: FontType { get }
    
    /// `largeTitle` with a Bold weight.
    var largeTitleBold: FontType { get }
    
    /// The font for first-level hierarchical headings.
    var title1: FontType { get }
        
    /// `title1` with a Bold weight.
    var title1Bold: FontType { get }
    
    /// The font for second-level hierarchical headings.
    var title2: FontType { get }
    
    /// `title2` with a Bold weight.
    var title2Bold: FontType { get }
    
    /// The font for third-level hierarchical headings.
    var title3: FontType { get }
    
    /// `title3` with a Bold weight.
    var title3Bold: FontType { get }
    
    /// The font for headings.
    var headline: FontType { get }
    
    /// `headline` with a Bold weight.
    var headlineBold: FontType { get }
    
    /// The font for body text.
    var body: FontType { get }
    
    /// `body` with a Bold weight.
    var bodyBold: FontType { get }
    
    /// The font for callouts.
    var callout: FontType { get }
    
    /// `callout` with a Bold weight.
    var calloutBold: FontType { get }
    
    /// The font for subheadings.
    var subheadline: FontType { get }
    
    /// `subheadline` with a Bold weight.
    var subheadlineBold: FontType { get }
    
    /// The font for footnotes.
    var footnote: FontType { get }
    
    /// `footnote` with a Bold weight.
    var footnoteBold: FontType { get }
    
    /// The font for standard captions.
    var caption1: FontType { get }

    /// `caption1` with a Bold weight.
    var caption1Bold: FontType { get }
    
    /// The font for alternate captions.
    var caption2: FontType { get }
    
    /// `caption2` with a Bold weight.
    var caption2Bold: FontType { get }
}
