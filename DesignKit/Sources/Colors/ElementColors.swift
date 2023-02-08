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
    // MARK: - Compound
    
    private let compound = CompoundColors()
    
    public var accent: Color { systemPrimaryLabel }
    public var alert: Color { compound.alert }
    public var links: Color { compound.links }
    public var primaryContent: Color { compound.primaryContent }
    public var secondaryContent: Color { compound.secondaryContent }
    public var tertiaryContent: Color { compound.tertiaryContent }
    public var quaternaryContent: Color { compound.quaternaryContent }
    public var quinaryContent: Color { compound.quinaryContent }
    public var system: Color { compound.system }
    public var background: Color { compound.background }
    // Should be the accent color
    public var brand: Color { compound.accent }
    
    public var contentAndAvatars: [Color] { compound.contentAndAvatars }
    
    // MARK: - System
    
    public var systemPrimaryLabel: Color { .primary }
    public var systemSecondaryLabel: Color { .secondary }
    public var systemTertiaryLabel: Color { Color(.tertiaryLabel) }
    public var systemQuaternaryLabel: Color { Color(.quaternaryLabel) }
    
    public var systemPrimaryBackground: Color { Color(.systemBackground) }
    public var systemSecondaryBackground: Color { Color(.secondarySystemBackground) }
    
    public var systemGray: Color { Color(.systemGray) }
    public var systemGray2: Color { Color(.systemGray2) }
    public var systemGray3: Color { Color(.systemGray3) }
    public var systemGray4: Color { Color(.systemGray4) }
    public var systemGray5: Color { Color(.systemGray5) }
    public var systemGray6: Color { Color(.systemGray6) }

    public func avatarBackground(for contentId: String) -> Color {
        let colorIndex = Int(contentId.hashCode % Int32(contentAndAvatars.count))
        return contentAndAvatars[colorIndex % contentAndAvatars.count]
    }
    
    // MARK: - Temp
    
    public var bubblesYou: Color {
        Color(UIColor { collection in
            // Note: Light colour doesn't currently match Figma.
            collection.userInterfaceStyle == .light ? .element.systemGray5 : UIColor(red: 0.16, green: 0.18, blue: 0.21, alpha: 1)
        })
    }
    
    public var bubblesNotYou: Color {
        Color(UIColor { collection in
            // Note: Light colour doesn't currently match Figma.
            collection.userInterfaceStyle == .light ? .element.systemGray6 : .element.system
        })
    }
}

// MARK: UIKit

public extension UIColor {
    /// The colors from Compound, as dynamic colors that automatically update for light and dark mode.
    static let element = ElementUIColors()
}

@objcMembers public class ElementUIColors: NSObject {
    // MARK: - Compound
    
    private let compound = CompoundUIColors()
    
    public var accent: UIColor { systemPrimaryLabel }
    public var alert: UIColor { compound.alert }
    public var links: UIColor { compound.links }
    public var primaryContent: UIColor { compound.primaryContent }
    public var secondaryContent: UIColor { compound.secondaryContent }
    public var tertiaryContent: UIColor { compound.tertiaryContent }
    public var quaternaryContent: UIColor { compound.quaternaryContent }
    public var quinaryContent: UIColor { compound.quinaryContent }
    public var system: UIColor { compound.system }
    public var background: UIColor { compound.background }
    
    public var contentAndAvatars: [UIColor] { compound.contentAndAvatars }
    
    // MARK: - System
    
    public var systemPrimaryLabel: UIColor { .label }
    public var systemSecondaryLabel: UIColor { .secondaryLabel }
    public var systemTertiaryLabel: UIColor { .tertiaryLabel }
    public var systemQuaternaryLabel: UIColor { .quaternaryLabel }
    
    public var systemPrimaryBackground: UIColor { .systemBackground }
    public var systemSecondaryBackground: UIColor { .secondarySystemBackground }
    
    public var systemGray: UIColor { .systemGray }
    public var systemGray2: UIColor { .systemGray2 }
    public var systemGray3: UIColor { .systemGray3 }
    public var systemGray4: UIColor { .systemGray4 }
    public var systemGray5: UIColor { .systemGray5 }
    public var systemGray6: UIColor { .systemGray6 }

    public func avatarBackground(for contentId: String) -> UIColor {
        let colorIndex = Int(contentId.hashCode % Int32(contentAndAvatars.count))
        return contentAndAvatars[colorIndex % contentAndAvatars.count]
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
