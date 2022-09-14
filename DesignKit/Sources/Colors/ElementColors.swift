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
    
    // MARK: - Temp
    
    private var tempActionBlack: UIColor { UIColor(red: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 1.0) }
    
    public var tempActionBackground: Color {
        Color(UIColor { collection in
            collection.userInterfaceStyle == .light ? tempActionBlack : .white
        })
    }
    
    public var tempActionForeground: Color {
        Color(UIColor { collection in
            collection.userInterfaceStyle == .light ? .white : tempActionBlack
        })
    }
    
    public var tempActionBackgroundTint: Color { tempActionBackground.opacity(0.2) }
    public var tempActionForegroundTint: Color { tempActionForeground.opacity(0.2) }
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
    
    // MARK: - Temp
    
    private var tempActionBlack: UIColor { UIColor(red: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 1.0) }
    
    public var tempActionBackground: UIColor {
        UIColor { collection in
            collection.userInterfaceStyle == .light ? self.tempActionBlack : .white
        }
    }
    
    public var tempActionForeground: UIColor {
        UIColor { collection in
            collection.userInterfaceStyle == .light ? .white : self.tempActionBlack
        }
    }
    
    public var tempActionBackgroundTint: UIColor { tempActionBackground.withAlphaComponent(0.2) }
    public var tempActionForegroundTint: UIColor { tempActionForeground.withAlphaComponent(0.2) }
}
