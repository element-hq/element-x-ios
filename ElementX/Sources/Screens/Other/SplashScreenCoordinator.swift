//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class SplashScreenCoordinator: CoordinatorProtocol {
    func toPresentable() -> AnyView {
        AnyView(SplashScreen())
    }
}

/// The app's splash screen. This screen is shown after the LaunchScreen
/// until the app is ready to show the relevant coordinator. The design of
/// these 2 screens are matched.
struct SplashScreen: View {
    var body: some View {
        Color.compound.bgCanvasDefault.ignoresSafeArea()
    }
}

struct SplashScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SplashScreen()
    }
}
