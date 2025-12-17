//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A layout that separates the main content of a screen from the buttons shown at
/// the bottom for a dialogs that fill the entire screen. On larger devices (iPad/Mac),
/// the height is constrained to keep the content relatively close to the buttons. If
/// the content overflows the space available, it will become scrollable.
///
/// The background color behind the buttons is read from the `backgroundStyle`
/// environment value, so make sure to set this to match the screen's background.
struct FullscreenDialog<Content: View, BottomContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.backgroundStyle) private var backgroundStyle
    
    /// Padding applied to the top of the content automatically. Use `UIConstants` for preset values.
    var topPadding: CGFloat = UIConstants.titleTopPaddingToNavigationBar
    /// Padding applied to the content automatically
    var horizontalPadding: CGFloat = 16
    /// Padding applied to the buttons automatically
    var bottomHorizontalPadding: CGFloat = 16
    /// The spacing between the content and the buttons.
    var spacing: CGFloat = 16
    
    /// The type of background that should be shown behind the content. This
    /// will be hidden if the main content extends behind the bottom content.
    var background: FullscreenDialogBackground?
    
    /// The main content shown at the top of the layout.
    @ViewBuilder var content: () -> Content
    /// The content shown at the bottom of the layout.
    @ViewBuilder var bottomContent: () -> BottomContent
    
    /// Whether or not the screen should show its background.
    @State private var showsBackground = true
    /// The background style given to the bottom content.
    private var bottomContentBackgroundStyle: AnyShapeStyle? {
        if background != nil, showsBackground {
            AnyShapeStyle(Color.clear)
        } else {
            backgroundStyle
        }
    }
    
    var body: some View {
        ZStack {
            if let background, showsBackground {
                Color.clear
                    .background(alignment: .bottom) {
                        background.image
                    }
                    .ignoresSafeArea()
            }
            
            if dynamicTypeSize < .accessibility1 {
                standardLayout
            } else {
                accessibilityLayout
            }
        }
    }
    
    /// A layout where the content scrolls with the bottom content overlaid. Used with regular font sizes.
    @MainActor var standardLayout: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                    
                    content()
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topPadding)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    bottomContent()
                        .readableFrame()
                        .padding(.horizontal, bottomHorizontalPadding)
                        .padding(.top, spacing)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .background(bottomContentBackgroundStyle ?? AnyShapeStyle(Color.clear))
            }
        }
        .introspect(.scrollView, on: .supportedVersions, customize: updateBackgroundVisibility)
    }
    
    /// A continuously scrolling layout used for accessibility font sizes.
    private var accessibilityLayout: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                    
                    content()
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topPadding)
                    
                    Spacer(minLength: spacing)
                    
                    bottomContent()
                        .readableFrame()
                        .padding(.horizontal, bottomHorizontalPadding)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    func updateBackgroundVisibility(scrollView: UIScrollView) {
        guard dynamicTypeSize < .accessibility1 else {
            if !showsBackground {
                showsBackground = true
            }
            return
        }
        
        DispatchQueue.main.async { // Don't modify the state during a view update.
            let insetHeight = scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom
            let availableHeight = scrollView.frame.height - insetHeight
            let shouldShowBackground = scrollView.contentSize.height < availableHeight
            
            if showsBackground != shouldShowBackground {
                showsBackground = shouldShowBackground
            }
        }
    }
}

/// The different types of background supported by the `FullscreenDialog` view.
enum FullscreenDialogBackground {
    /// The bottom gradient from the FTUE flow.
    case gradient
    
    private var asset: ImageAsset {
        switch self {
        case .gradient:
            Asset.Images.backgroundBottom
        }
    }
    
    private var capInsets: EdgeInsets {
        switch self {
        case .gradient:
            EdgeInsets(top: 0, leading: 0, bottom: 250, trailing: 0)
        }
    }
    
    /// The image that represents the background.
    var image: Image {
        Image(asset: asset)
            .resizable(capInsets: capInsets)
    }
}

struct FullscreenDialog_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar) {
            content
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .previewDisplayName("Plain")
        
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar, background: .gradient) {
            content
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .previewDisplayName("Gradient")
    }
    
    private static var content: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 50))
                .foregroundColor(.compound.textPrimary)
                .padding()
                .background(Color.compound.bgSubtlePrimary, in: Circle())
                .padding(.bottom, 8)
            Text("Hello, World")
                .font(.compound.headingLG)
                .foregroundColor(.compound.textPrimary)
            Text("I am a subtitle")
                .font(.compound.bodyLG)
                .foregroundColor(.compound.textSecondary)
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("We care about you", systemImage: "person")
                Label("Environmentally focussed", systemImage: "leaf")
                Label("All of the options", systemImage: "wrench")
                Label("Fun to use", systemImage: "logo.xbox")
            }
        }
    }
    
    private static var buttons: some View {
        VStack(spacing: 16) {
            Button { } label: {
                Text("Continue")
                    .font(.compound.bodyLGSemibold)
            }
            .buttonStyle(.compound(.primary))
            
            Button { } label: {
                Text("More options")
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
        }
    }
}
