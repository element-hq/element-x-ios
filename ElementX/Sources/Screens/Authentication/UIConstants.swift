//
// Copyright 2022 New Vector Ltd
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
