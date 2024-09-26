import SwiftUI

public extension Color {
    static let zero = ZeroColors()
}

public extension ShapeStyle where Self == Color {
    static var zero: ZeroColors { Self.zero }
}

public struct ZeroColors {
    public let iconSuccessPrimary = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green900
    public let iconAccentPrimary = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green900
    public let iconAccentTertiary = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green800
    public let borderSuccessSubtle = Asset.Colors.blue11.swiftUIColor.opacity(0.5) // CompoundCoreColorTokens.green500
    public let bgAccentPressed = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green1100
    public let bgAccentHovered = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green1000
    public let bgAccentRest = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green900
    public let bgSuccessSubtle = Asset.Colors.blue11.swiftUIColor.opacity(0.2) // CompoundCoreColorTokens.green200
    public let textSuccessPrimary = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green900
    public let textActionAccent = Asset.Colors.blue11.swiftUIColor // CompoundCoreColorTokens.green900
    
    public let _badgeTextSuccess = Asset.Colors.blue11.swiftUIColor // coreTokens.green1100
    public let _textOwnPill = Asset.Colors.blue11.swiftUIColor // coreTokens.green1100
    public let _bgAccentSelected = Asset.Colors.blue11.swiftUIColor.opacity(0.3) // coreTokens.green300
    public let _bgBubbleHighlighted = Asset.Colors.blue11.swiftUIColor.opacity(0.3) // coreTokens.green300
    public let _bgBadgeSuccess = Asset.Colors.blue11.swiftUIColor.opacity(0.3) // coreTokens.alphaGreen300
}
