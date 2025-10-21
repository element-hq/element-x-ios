//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    func accessibleLongPress(named name: String, action: @escaping () -> Void) -> some View {
        modifier(AccessibleLongPress(name: name, action: action))
    }
}

struct AccessibleLongPress: ViewModifier {
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled
    let name: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if isVoiceOverEnabled {
            content
                .accessibilityAction(named: name) {
                    action()
                }
        } else {
            content
                .longPressWithFeedback {
                    action()
                }
        }
    }
}
