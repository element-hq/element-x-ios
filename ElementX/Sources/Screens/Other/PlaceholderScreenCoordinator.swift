//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    private let hideBrandChrome: Bool
    
    init(hideBrandChrome: Bool = true) {
        self.hideBrandChrome = hideBrandChrome
    }
    
    func toPresentable() -> AnyView {
        AnyView(PlaceholderScreen(hideBrandChrome: hideBrandChrome))
    }
}

/// The screen shown in split view when the detail has no content.
struct PlaceholderScreen: View {
    let hideBrandChrome: Bool
    
    var body: some View {
        AuthenticationStartLogo(isOnGradient: !hideBrandChrome)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if !hideBrandChrome {
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
        PlaceholderScreen(hideBrandChrome: true)
            .previewDisplayName("Screen")
        
        PlaceholderScreen(hideBrandChrome: false)
            .previewDisplayName("With background")
        
        NavigationSplitView {
            List {
                ForEach("Nothing to see here".split(separator: " "), id: \.self) { word in
                    Text(word)
                }
            }
        } detail: {
            PlaceholderScreen(hideBrandChrome: true)
        }
        .previewDisplayName("Split View")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
