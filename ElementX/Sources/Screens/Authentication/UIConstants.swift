//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// Standard constants used across the app's UI.
enum UIConstants {
    static let maxContentHeight: CGFloat = 750
    
    /// The padding used between the top of the main content's icon and the navigation bar.
    static let iconTopPaddingToNavigationBar: CGFloat = 43
    /// The padding used between the top of the main content's title and the navigation bar.
    static let titleTopPaddingToNavigationBar: CGFloat = 32
    /// The padding used between the footer and the bottom of the view.
    static let actionButtonBottomPadding: CGFloat = 24
    
    /// The padding used to the top of the view for breaker screens that don't have a navigation bar.
    static let startScreenBreakerScreenTopPadding: CGFloat = 80

    /// The height to use for top/bottom spacers to pad the views to fit the `maxContentHeight`.
    static func spacerHeight(in geometry: GeometryProxy) -> CGFloat {
        max(0, (geometry.size.height - maxContentHeight) / 2)
    }
}
