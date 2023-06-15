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

import DesignTokens
import SwiftUI

// MARK: SwiftUI

public extension Color {
    static let element = ElementColors()
    static let global = Color.global
}

public struct ElementColors {
    // MARK: - Legacy Compound
    
    private let colors = DesignTokens.CompoundColors()
    private let uiColors = DesignTokens.CompoundUIColors()
    
    @available(*, deprecated, message: "Use textActionPrimary from Compound.")
    public var accent: Color { colors.primaryContent }
    @available(*, deprecated, message: "Use textCriticalPrimary/iconCriticalPrimary from Compound.")
    public var alert: Color { colors.alert }
    @available(*, deprecated, message: "Use textLinkExternal from Compound.")
    public var links: Color { colors.links }
    @available(*, deprecated, message: "Use textPrimary/iconPrimary from Compound.")
    public var primaryContent: Color { colors.primaryContent }
    @available(*, deprecated, message: "Use textSecondary/iconSecondary from Compound.")
    public var secondaryContent: Color { colors.secondaryContent }
    @available(*, deprecated, message: "Use bgSubtleSecondary from Compound.")
    public var system: Color { colors.system }
    @available(*, deprecated, message: "Use bgCanvasDefault from Compound for backgrounds. For text or icons use textOnSolidPrimary/iconOnSolidPrimary.")
    public var background: Color { colors.background }
    @available(*, deprecated, message: "Use textActionAccent/iconAccentTertiary from Compound.")
    public var brand: Color { colors.accent }
    
    @available(*, deprecated, message: "Use iconTertiary form Compound for icons. For text use textSecondary. For borders and backgrounds check with Design.")
    public var tertiaryContent: Color { colors.tertiaryContent }
    @available(*, deprecated, message: "Use iconQuaternary from Compound for icons. For text, borders and backgrounds check with Design.")
    public var quaternaryContent: Color { colors.quaternaryContent }
    @available(*, deprecated, message: "Check with Design for the tokens to use from Compound.")
    public var quinaryContent: Color { colors.quinaryContent }
    
    public var contentAndAvatars: [Color] { colors.contentAndAvatars }
    
    public func avatarBackground(for contentId: String) -> Color {
        let colorIndex = Int(contentId.hashCode % Int32(contentAndAvatars.count))
        return contentAndAvatars[colorIndex % contentAndAvatars.count]
    }
    
    // MARK: - Temp
    
    public var bubblesYou: Color {
        Color(UIColor { collection in
            // Note: Light colour doesn't currently match Figma.
            collection.userInterfaceStyle == .light ? .systemGray5 : UIColor(red: 0.16, green: 0.18, blue: 0.21, alpha: 1)
        })
    }
    
    public var bubblesNotYou: Color {
        Color(UIColor { collection in
            // Note: Light colour doesn't currently match Figma.
            collection.userInterfaceStyle == .light ? .systemGray6 : uiColors.system
        })
    }
    
    /// The colour to use on the background of a Form or grouped List.
    ///
    /// This colour is a special case as it uses `system` in light mode and `background` in dark mode.
    public var formBackground: Color {
        Color(UIColor { collection in
            collection.userInterfaceStyle == .light ? uiColors.system : uiColors.background
        })
    }
    
    /// The background colour of a row in a Form or grouped List.
    ///
    /// This colour is a special case as it uses `background` in light mode and `system` in dark mode.
    public var formRowBackground: Color {
        Color(UIColor { collection in
            collection.userInterfaceStyle == .light ? uiColors.background : uiColors.system
        })
    }
}

private extension String {
    /// Calculates a numeric hash same as Element Web
    /// See original function here https://github.com/matrix-org/matrix-react-sdk/blob/321dd49db4fbe360fc2ff109ac117305c955b061/src/utils/FormattingUtils.js#L47
    var hashCode: Int32 {
        var hash: Int32 = 0

        for character in self {
            let shiftedHash = hash << 5
            hash = shiftedHash.subtractingReportingOverflow(hash).partialValue + Int32(character.unicodeScalars[character.unicodeScalars.startIndex].value)
        }
        return abs(hash)
    }
}
