//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ElementNavigationStack<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        if ProcessInfo.isRunningAccessibilityTests {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }
}
