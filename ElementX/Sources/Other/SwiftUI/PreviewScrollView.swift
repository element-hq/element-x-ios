//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Only use in Previews! This useful scroll view allows you to still have a scroll view when previewing in Xcode
/// but ignores it when running the tests, which allows you to still use it's content directly in preview tests
/// and render the preview with `sizeThatFits` layout.
struct PreviewScrollView<Content: View>: View {
    var content: () -> Content
    
    var body: some View {
        if ProcessInfo.isRunningTests {
            content()
        } else {
            ScrollView {
                content()
            }
        }
    }
}
