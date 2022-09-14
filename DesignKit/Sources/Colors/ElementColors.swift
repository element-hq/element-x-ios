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
    
    public var accent: Color { .primary }
    public var alert: Color { .global.vermillon }
    public var links: Color { .global.links }
    public var primaryContent: Color { .primary }
    public var secondaryContent: Color { .secondary }
    public var tertiaryContent: Color { Color(.tertiaryLabel) }
    public var quaternaryContent: Color { Color(.quaternaryLabel) }
    public var quinaryContent: Color { Color(.secondarySystemBackground) }
    public var system: Color { Color(.separator) }
    public var background: Color { Color(.systemBackground) }
    
    public let contentAndAvatars: [Color] = CompoundColors().contentAndAvatars
    
    // MARK: - System
    
    public var systemGray: Color { Color(.systemGray) }
    public var systemGray2: Color { Color(.systemGray2) }
    public var systemGray3: Color { Color(.systemGray3) }
    public var systemGray4: Color { Color(.systemGray4) }
    public var systemGray5: Color { Color(.systemGray5) }
    public var systemGray6: Color { Color(.systemGray6) }
    
    public var secondaryBackground: Color { Color(.secondarySystemBackground) }
    
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
    
    public var accent: UIColor { .label }
    public var alert: UIColor { .global.vermillon }
    public var links: UIColor { .global.links }
    public var primaryContent: UIColor { .label }
    public var secondaryContent: UIColor { .secondaryLabel }
    public var tertiaryContent: UIColor { .tertiaryLabel }
    public var quaternaryContent: UIColor { .quaternaryLabel }
    public var quinaryContent: UIColor { .secondarySystemBackground }
    public var system: UIColor { .separator }
    public var background: UIColor { .systemBackground }
    
    public let contentAndAvatars: [UIColor] = CompoundUIColors().contentAndAvatars
    
    // MARK: - System
    
    public var systemGray: UIColor { .systemGray }
    public var systemGray2: UIColor { .systemGray2 }
    public var systemGray3: UIColor { .systemGray3 }
    public var systemGray4: UIColor { .systemGray4 }
    public var systemGray5: UIColor { .systemGray5 }
    public var systemGray6: UIColor { .systemGray6 }
    
    public var secondaryBackground: UIColor { .secondarySystemBackground }
    
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
