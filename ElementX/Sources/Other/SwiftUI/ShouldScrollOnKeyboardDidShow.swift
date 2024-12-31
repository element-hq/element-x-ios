//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Adds a scroll view reader to the view and scrolls to the provided id if the condition is true, so far it only works properly if the item is the last in the scroll view.
    func shouldScrollOnKeyboardDidShow(_ shouldScroll: Bool, to id: any Hashable) -> some View {
        ScrollViewReader { scrollView in
            onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)) { _ in
                guard shouldScroll else { return }
                // Scroll to the footer of the alias when the keyboard appears
                withAnimation {
                    // We could improve this in the future by also providing the anchor as an argument
                    scrollView.scrollTo(id, anchor: .top)
                }
            }
        }
    }
}
