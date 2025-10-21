//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    private let hideBrandChrome: Bool
    private let hideGradientBackground: Bool
    
    init(hideBrandChrome: Bool, hideGradientBackground: Bool = true) {
        self.hideBrandChrome = hideBrandChrome
        self.hideGradientBackground = hideBrandChrome || hideGradientBackground
    }
    
    func toPresentable() -> AnyView {
        AnyView(PlaceholderScreen(hideBrandChrome: hideBrandChrome, hideGradientBackground: hideGradientBackground))
    }
}

/// The screen shown in split view when the detail has no content.
struct PlaceholderScreen: View {
    let hideBrandChrome: Bool
    let hideGradientBackground: Bool
    
    var body: some View {
        AuthenticationStartLogo(hideBrandChrome: hideBrandChrome)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if !hideGradientBackground {
                    AuthenticationStartScreenBackgroundImage()
                }
            }
            .background()
            .backgroundStyle(.compound.bgCanvasDefault)
            .ignoresSafeArea(edges: .top) // Remain vertically centred even if there's a navigation bar.
            .ignoresSafeArea(.keyboard) // Specifically for the lock screen, but make sense everywhere.
    }
}

struct PlaceholderScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        PlaceholderScreen(hideBrandChrome: false, hideGradientBackground: false)
            .previewDisplayName("With chrome and background")
        
        PlaceholderScreen(hideBrandChrome: false, hideGradientBackground: true)
            .previewDisplayName("With chrome and no background")
        
        PlaceholderScreen(hideBrandChrome: true, hideGradientBackground: true)
            .previewDisplayName("Without chrome")
        
        NavigationSplitView {
            List {
                ForEach("Nothing to see here".split(separator: " "), id: \.self) { word in
                    Text(word)
                }
            }
        } detail: {
            PlaceholderScreen(hideBrandChrome: false, hideGradientBackground: true)
        }
        .previewDisplayName("Split View")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
