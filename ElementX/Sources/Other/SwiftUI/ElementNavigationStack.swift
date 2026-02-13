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
        #if DEBUG
        if ProcessInfo.isRunningAccessibilityTests {
            // Wrap in VStack to safely apply .id() since applying .id() directly to NavigationStack crashes on iOS 26
            VStack(spacing: 0) {
                NavigationStack {
                    content
                }
            }
        } else {
            NavigationStack {
                content
            }
        }
        #else
        NavigationStack {
            content
        }
        #endif
    }
}
