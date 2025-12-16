//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Our standard screen header that includes a title and icon along with
/// optional subtitle and button components.
///
/// **Note:** By default this component includes the standard padding
/// specified in the Figma, however you may need to customise it using
/// the `insets` parameter.
public struct TitleAndIcon: View {
    private let title: String
    private let subtitle: String?
    private let icon: KeyPath<CompoundIcons, Image>
    private let iconStyle: BigIcon.Style
    private let button: ButtonDetails?
    private let insets: EdgeInsets
    
    public init(title: String,
                subtitle: String? = nil,
                icon: KeyPath<CompoundIcons, Image>,
                iconStyle: BigIcon.Style,
                button: ButtonDetails? = nil,
                insets: EdgeInsets = .init(top: 24, leading: 24, bottom: 40, trailing: 24)) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconStyle = iconStyle
        self.button = button
        self.insets = insets
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            BigIcon(icon: icon, style: iconStyle)
            
            VStack(spacing: 8) {
                Text(title)
                    .foregroundColor(.compound.textPrimary)
                    .font(.compound.headingMDBold)
                    .multilineTextAlignment(.center)
                
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let button {
                Button(button.title, action: button.action)
                    .buttonStyle(.compound(.tertiary, size: .small))
            }
        }
        .padding(insets)
    }
}

public extension TitleAndIcon {
    /// Everything required to construct the `TitleAndIcon` view's optional button.
    struct ButtonDetails {
        public let title: String
        public let action: () -> Void
        
        init(title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
    }
}

// MARK: - Previews

public struct TitleAndIcon_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        states
    }
    
    public static var states: some View {
        VStack(spacing: 20) {
            TitleAndIcon(title: "Headline",
                         icon: \.circle,
                         iconStyle: .defaultSolid)
            
            TitleAndIcon(title: "Headline",
                         subtitle: "Description goes here",
                         icon: \.circle,
                         iconStyle: .defaultSolid)
            
            TitleAndIcon(title: "Headline",
                         subtitle: "Description goes here",
                         icon: \.circle,
                         iconStyle: .defaultSolid,
                         button: .init(title: "Learn more") { })
        }
    }
}
