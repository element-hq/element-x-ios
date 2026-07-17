//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// An image that is styled for use as the main/top/hero screen icon. This component
/// takes a compound icon. If you would like to apply it to an SFSymbol, you can call
/// the `bigIcon()` modifier directly on the Image.
public struct BigIcon: View {
    public enum Style {
        case defaultSolid
        case `default`
        case alertSolid
        case alert
        case successSolid
        case success
        
        var foregroundColor: Color {
            switch self {
            case .defaultSolid, .default:
                .compound.iconPrimary
            case .alertSolid, .alert:
                .compound.iconCriticalPrimary
            case .successSolid, .success:
                .compound.iconSuccessPrimary
            }
        }
        
        var backgroundFillColor: Color {
            switch self {
            case .defaultSolid:
                .compound.bgSubtleSecondary
            case .alertSolid:
                .compound.bgCriticalSubtle
            case .successSolid:
                .compound.bgSuccessSubtle
            case .default, .alert, .success:
                .compound.bgCanvasDefault
            }
        }
    }
    
    /// The icon that is shown.
    private let icon: KeyPath<CompoundIcons, Image>
    private let style: Style
    
    public init(icon: KeyPath<CompoundIcons, Image>, style: Style = .defaultSolid) {
        self.icon = icon
        self.style = style
    }
    
    public var body: some View {
        CompoundIcon(icon, size: .custom(32), relativeTo: .compound.headingLG)
            .modifier(BigIconModifier(style: style))
    }
}

public extension Image {
    /// Styles the image for use as the main/top/hero screen icon. You should prefer
    /// the BigIcon component when possible, by using an icon from Compound.
    func bigIcon(insets: CGFloat = 16, style: BigIcon.Style = .defaultSolid) -> some View {
        resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .scaledPadding(insets, relativeTo: .compound.headingLG)
            .modifier(BigIconModifier(style: style))
    }
}

private struct BigIconModifier: ViewModifier {
    let style: BigIcon.Style
    
    func body(content: Content) -> some View {
        content
            .scaledFrame(size: 64, relativeTo: .compound.headingLG)
            .foregroundColor(style.foregroundColor)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(style.backgroundFillColor)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

public struct BigIcon_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        VStack(spacing: 40) {
            HStack(spacing: 20) {
                BigIcon(icon: \.lockSolid)
                Image(systemName: "hourglass")
                    .bigIcon()
                Image(systemSymbol: .serverRack)
                    .bigIcon(insets: 19)
            }
            
            states
        }
    }
    
    public static var states: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                BigIcon(icon: \.helpSolid)
                BigIcon(icon: \.helpSolid, style: .default)
            }
            
            HStack(spacing: 20) {
                BigIcon(icon: \.errorSolid, style: .alertSolid)
                BigIcon(icon: \.errorSolid, style: .alert)
            }
            
            HStack(spacing: 20) {
                BigIcon(icon: \.checkCircleSolid, style: .successSolid)
                BigIcon(icon: \.checkCircleSolid, style: .success)
            }
        }
    }
}
