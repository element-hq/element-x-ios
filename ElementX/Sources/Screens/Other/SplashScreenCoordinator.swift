//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

@Observable
class SplashScreenCoordinator: CoordinatorProtocol {
    /// Whether the splash is showing room-list placeholders instead of a blank canvas.
    private(set) var showsSkeletons = false
    
    /// Swap the blank canvas for room-list skeletons: an affordance that the app is busy
    /// (e.g. a store migration) rather than hung, when the session takes a while to restore.
    func showSkeletons() {
        showsSkeletons = true
    }
    
    func toPresentable() -> AnyView {
        AnyView(SplashScreen(coordinator: self))
    }
}

/// The app's splash screen. This screen is shown after the LaunchScreen
/// until the app is ready to show the relevant coordinator. The design of
/// these 2 screens are matched.
struct SplashScreen: View {
    var coordinator: SplashScreenCoordinator?
    
    var body: some View {
        ZStack {
            Color.compound.bgCanvasDefault.ignoresSafeArea()
            
            if coordinator?.showsSkeletons == true {
                skeletons
            }
        }
    }
    
    /// Mirrors the home screen's `.skeletons` mode so the hand-over to the real list is seamless.
    private var skeletons: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in
                    HomeScreenRoomCell(room: .placeholder(), isSelected: false, mediaProvider: nil) { _ in }
                        .redacted(reason: .placeholder)
                        .shimmer()
                }
            }
        }
        .disabled(true)
        .accessibilityRepresentation {
            Text(L10n.commonLoading)
        }
    }
}

struct SplashScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SplashScreen()
    }
}
