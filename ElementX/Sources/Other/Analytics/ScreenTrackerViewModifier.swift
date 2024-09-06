//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
import SwiftUI

/// `ScreenTrackerViewModifier` is a helper class used to track PostHog screen from SwiftUI screens.
struct ScreenTrackerViewModifier: ViewModifier {
    @Environment(\.analyticsService) private var analyticsService
    
    let screen: AnalyticsEvent.MobileScreen.ScreenName
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .onAppear {
                analyticsService.track(screen: screen)
            }
    }
}

extension View {
    func track(screen: AnalyticsEvent.MobileScreen.ScreenName) -> some View {
        modifier(ScreenTrackerViewModifier(screen: screen))
    }
}
