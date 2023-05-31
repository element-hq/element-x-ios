//
// Copyright 2023 New Vector Ltd
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
    
    /// Padding applied to the top of the content automatically. Use `UIConstants` for preset values.
    var topPadding: CGFloat = UIConstants.titleTopPaddingToNavigationBar
    /// Padding applied to the content and buttons automatically
    var horizontalPadding: CGFloat = 16
    /// The spacing between the content and the buttons.
    var spacing: CGFloat = 16
    
    /// The main content shown at the top of the layout.
    @ViewBuilder var content: () -> Content
    /// The content shown at the bottom of the layout.
    @ViewBuilder var bottomContent: () -> BottomContent
    
    var body: some View {
        if dynamicTypeSize < .accessibility1 {
            standardLayout
        } else {
            accessibilityLayout
        }
    }
    
    /// A layout where the content scrolls with the bottom content overlaid. Used with regular font sizes.
    var standardLayout: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
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
                VStack {
                    bottomContent()
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, spacing)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .background()
            }
        }
    }
    
    /// A continuously scrolling layout used for accessibility font sizes.
    var accessibilityLayout: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                    
                    content()
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topPadding)
                    
                    Spacer(minLength: spacing)
                    
                    bottomContent()
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct FullscreenDialog_Previews: PreviewProvider {
    static var previews: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar) {
            content
        } bottomContent: {
            buttons
        }
        .background()
        .environment(\.backgroundStyle, AnyShapeStyle(Color.element.background))
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
            .buttonStyle(.elementAction(.xLarge))
            
            Button { } label: {
                Text("More options")
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
        }
    }
}
