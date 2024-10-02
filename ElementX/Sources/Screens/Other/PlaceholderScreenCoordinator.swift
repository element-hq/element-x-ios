//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    private let showsBackgroundGradient: Bool
    
    init(showsBackgroundGradient: Bool = false) {
        self.showsBackgroundGradient = showsBackgroundGradient
    }
    
    func toPresentable() -> AnyView {
        AnyView(PlaceholderScreen(showsBackgroundGradient: showsBackgroundGradient))
    }
}

/// The screen shown in split view when the detail has no content.
struct PlaceholderScreen: View {
    let showsBackgroundGradient: Bool
    
    var body: some View {
        AuthenticationStartLogo(isOnGradient: showsBackgroundGradient)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if showsBackgroundGradient {
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
        PlaceholderScreen(showsBackgroundGradient: false)
            .previewDisplayName("Screen")
        
        PlaceholderScreen(showsBackgroundGradient: true)
            .previewDisplayName("With background")
        
        NavigationSplitView {
            List {
                ForEach("Nothing to see here".split(separator: " "), id: \.self) { word in
                    Text(word)
                }
            }
        } detail: {
            PlaceholderScreen(showsBackgroundGradient: false)
        }
        .previewDisplayName("Split View")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
