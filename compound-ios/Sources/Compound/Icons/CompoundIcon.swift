//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@_exported import CompoundDesignTokens
import SwiftUI

public extension Image {
    /// The icons used by Element as defined in Compound Design Tokens.
    static let compound = CompoundIcons()
}

/// A view that displays an icon from Compound. The icon defaults to a size of 24pt
/// and scales with Dynamic Type, relative to any font given to it by the `font` modifier.
public struct CompoundIcon: View {
    /// The size of the icon.
    public enum Size {
        /// An icon size of 16pt.
        case xSmall
        /// An icon size of 20pt.
        case small
        /// An icon size of 24pt.
        case medium
        /// A custom icon size.
        case custom(CGFloat)
        
        var value: CGFloat {
            switch self {
            case .xSmall: return 16
            case .small: return 20
            case .medium: return 24
            case .custom(let size): return size
            }
        }
    }
    
    private var image: Image
    private var size: Size
    private var font: Font
    
    private var fontSize: FontSize {
        FontSize.reflecting(font) ?? .style(.body)
    }
    
    /// Creates an icon using a key path from the Compound tokens. The size will be
    /// 24pt and will scale relative to the `bodyLG` font when Dynamic Type is used.
    ///
    /// - Parameters:
    ///   - icon: The icon to show.
    public init(_ icon: KeyPath<CompoundIcons, Image>) {
        image = .compound[keyPath: icon]
        self.size = .medium
        self.font = .compound.bodyLG
    }
    
    /// Creates an icon using a key path from the Compound tokens.
    ///
    /// - Parameters:
    ///   - icon: The icon to show.
    ///   - size: The size of the icon.
    ///   - font: The font that should be used for scaling with Dynamic Type.
    public init(_ icon: KeyPath<CompoundIcons, Image>, size: Size, relativeTo font: Font) {
        image = .compound[keyPath: icon]
        self.size = size
        self.font = font
    }
    
    /// Creates an icon using a custom image to allow assets from outside
    /// of Compound to scale in the same way as icons. The size will be 24pt
    /// and will scale relative to the `bodyLG` font when Dynamic Type is used.
    ///
    /// - Parameters:
    ///   - customImage: The image that should be displayed
    ///
    /// ** Note:** The image should have a square frame or it may end up distorted.
    public init(customImage: Image) {
        image = customImage
        self.size = .medium
        self.font = .compound.bodyLG
    }
    
    /// Creates an icon using a custom image to allow assets from outside
    /// of Compound to scale in the same way as icons.
    ///
    /// - Parameters:
    ///   - customImage: The image that should be displayed
    ///   - size: The size of the icon.
    ///   - font: The font that should be used for scaling with Dynamic Type.
    ///
    /// ** Note:** The image should have a square frame or it may end up distorted.
    public init(customImage: Image, size: Size, relativeTo font: Font) {
        image = customImage
        self.size = size
        self.font = font
    }
    
    public var body: some View {
        image
            .resizable()
            .modifier(CompoundIconFrame(fontSize: size.value, textStyle: fontSize.style))
    }
}

/// A simple modifier that applies a square frame of a given size that will be
/// scaled dynamically based upon the specified text style.
private struct CompoundIconFrame: ViewModifier {
    @ScaledMetric private var size: CGFloat
    
    init(fontSize: CGFloat, textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: fontSize, relativeTo: textStyle)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
    }
}

public extension Label {
    /// Creates a label with an icon from Compound and a title generated from a string.
    /// The icon size will be 24pt, scaling relative to the `bodyLG` with Dynamic Type.
    /// - Parameters:
    ///   - title: A string used as the label’s title.
    ///   - icon: The icon to use from Compound.
    init(_ title: some StringProtocol, icon: KeyPath<CompoundIcons, Image>) where Title == Text, Icon == CompoundIcon {
        self.init {
            Text(title)
        } icon: {
            CompoundIcon(icon)
        }
    }
    
    /// Creates a label with an icon from Compound and a title generated from a string.
    /// - Parameters:
    ///   - title: A string used as the label’s title.
    ///   - icon: The icon to use from Compound.
    ///   - iconSize: The size of the icon.
    ///   - font: The font that the icon should scale relative to with Dynamic Type.
    init(_ title: some StringProtocol,
         icon: KeyPath<CompoundIcons, Image>,
         iconSize: CompoundIcon.Size,
         relativeTo font: Font) where Title == Text, Icon == CompoundIcon {
        self.init {
            Text(title)
        } icon: {
            CompoundIcon(icon, size: iconSize, relativeTo: font)
        }
    }
}

// MARK: - Previews

struct CompoundIcon_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        form
            .previewDisplayName("Form")
        buttons
            .padding(8)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Buttons")
        accessibilityIcons
            .previewDisplayName("Accessibility Icons Only")
        accessibilityLabels
            .previewDisplayName("Accessibility Labels")
    }
    
    static var accessibilityIcons: some View {
        VStack {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                HStack {
                    CompoundIcon(\.userProfile, size: .xSmall, relativeTo: .compound.bodyXS)
                    CompoundIcon(\.userProfile, size: .small, relativeTo: .compound.bodySM)
                    CompoundIcon(\.userProfile, size: .medium, relativeTo: .compound.bodyLG)
                }
                .dynamicTypeSize(size)
            }
        }
    }
    
    
    static var accessibilityLabels: some View {
        Grid(alignment: .leading) {
            ForEach(DynamicTypeSize.allCases, id: \.self) {
                size in
                GridRow {
                    Label("Test XS", icon: \.userProfile, iconSize: .xSmall, relativeTo: .compound.bodyXS)
                        .font(.compound.bodyXS)
                    Label("Test Small", icon: \.userProfile, iconSize: .small, relativeTo: .compound.bodySM)
                        .font(.compound.bodySM)
                    Label("Test Medium", icon: \.userProfile, iconSize: .medium, relativeTo: .compound.bodyLG)
                        .font(.compound.bodyLG)
                }
                .lineLimit(1)
                .dynamicTypeSize(size)
            }
        }
    }
    
    static var form: some View {
        Form {
            Section {
                ListRow(label: .action(title: "Plain Icon", icon: \.userProfile),
                        kind: .label)
                ListRow(label: .default(title: "Plain Icon", icon: \.userProfile),
                        kind: .label)
                ListRow(label: .default(title: "Plain Icon", systemIcon: .personCropCircle),
                        kind: .label)
            }
        }
        .compoundList()
        .safeAreaInset(edge: .bottom) {
            Button { } label: {
                Label("Button", icon: \.userProfile)
            }
            .buttonStyle(.compound(.primary))
            .padding()
        }
    }
    
    static var buttons: some View {
        VStack {
            Button { } label: {
                Label { Text("Body Large") } icon: {
                    CompoundIcon(\.userProfile, size: .medium, relativeTo: .compound.bodyLG)
                }
            }
            .font(.compound.bodyLG)
            .buttonStyle(.borderedProminent)
            
            Button { } label: {
                Label { Text("Body Small") } icon: {
                    CompoundIcon(\.userProfile, size: .small, relativeTo: .compound.bodySM)
                }
            }
            .font(.compound.bodySM)
            .buttonStyle(.borderedProminent)
            
            Button { } label: {
                Label { Text("Body xSmall") } icon: {
                    CompoundIcon(\.userProfile, size: .xSmall, relativeTo: .compound.bodyXS)
                }
            }
            .font(.compound.bodyXS)
            .buttonStyle(.borderedProminent)
        }
    }
}
