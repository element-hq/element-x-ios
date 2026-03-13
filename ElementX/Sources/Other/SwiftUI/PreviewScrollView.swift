//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

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
