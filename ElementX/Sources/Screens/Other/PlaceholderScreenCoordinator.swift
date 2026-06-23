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
        content
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

    @ViewBuilder
    private var content: some View {
        if hideBrandChrome {
            // GUA FORK: the empty iPad detail pane. AuthenticationStartLogo is resizable +
            // scaledToFit with no intrinsic cap, so without a frame it scales up to fill the
            // whole detail pane (the "giant logo" bug). Cap it and pair it with a subtle hint
            // so this reads as a tasteful empty state rather than a hero logo.
            VStack(spacing: 16) {
                AuthenticationStartLogo(isOnGradient: false)
                    .frame(maxWidth: 96, maxHeight: 96)

                Text(L10n.screenRoomlistEmptyMessage)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        } else {
            // Lock screen: keep the full-size branded hero logo on the gradient.
            AuthenticationStartLogo(isOnGradient: true)
        }
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
