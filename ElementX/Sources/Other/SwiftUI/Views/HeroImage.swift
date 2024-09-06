//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

/// An image that is styled for use as the main/top/hero screen icon. This component
/// takes a compound icon. If you would like to apply it to an SFSymbol, you can call
/// the `heroImage()` modifier directly on the Image.
struct HeroImage: View {
    enum Style {
        case normal
        case positive
        case subtle
        case critical
        
        var foregroundColor: Color {
            switch self {
            case .normal:
                return .compound.iconPrimary
            case .positive:
                return .compound.iconSuccessPrimary
            case .subtle:
                return .compound.iconSecondary
            case .critical:
                return .compound.iconCriticalPrimary
            }
        }
        
        var backgroundFillColor: Color {
            switch self {
            case .normal:
                return .compound.bgSubtleSecondary
            case .positive:
                return .compound.bgSuccessSubtle
            case .subtle:
                return .compound.bgSubtlePrimary
            case .critical:
                return .compound.bgCanvasDefault
            }
        }
    }
    
    /// The icon that is shown.
    let icon: KeyPath<CompoundIcons, Image>
    var style: Style = .normal
    
    var body: some View {
        CompoundIcon(icon, size: .custom(42), relativeTo: .title)
            .modifier(HeroImageModifier(style: style))
    }
}

extension Image {
    /// Styles the image for use as the main/top/hero screen icon. You should prefer
    /// the HeroImage component when possible, by using an icon from Compound.
    func heroImage(insets: CGFloat = 16, style: HeroImage.Style = .normal) -> some View {
        resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .scaledPadding(insets, relativeTo: .title)
            .modifier(HeroImageModifier(style: style))
    }
}

private struct HeroImageModifier: ViewModifier {
    let style: HeroImage.Style
    
    func body(content: Content) -> some View {
        content
            .scaledFrame(size: 70, relativeTo: .title)
            .foregroundColor(style.foregroundColor)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(style.backgroundFillColor)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct HeroImage_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 20) {
            HeroImage(icon: \.lockSolid)
            Image(systemName: "hourglass")
                .heroImage()
            Image(asset: Asset.Images.serverSelectionIcon)
                .heroImage(insets: 19)
        }
    }
}
