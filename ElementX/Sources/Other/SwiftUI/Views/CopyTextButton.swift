//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A button that contains text that is copied on tap
struct CopyTextButton: View {
    let content: String

    var body: some View {
        Button {
            UIPasteboard.general.string = content
        } label: {
            Label {
                Text(content)
                    .lineLimit(1)
            } icon: {
                CompoundIcon(\.copy, size: .small, relativeTo: .compound.bodyLG)
                    .accessibilityHidden(true)
            }
            .font(.compound.bodyLG)
            .foregroundStyle(.compound.textSecondary)
            .labelStyle(.custom(spacing: 4, iconLayout: .trailing))
        }
        .accessibilityHint(L10n.actionCopy)
    }
}

struct CopyTextButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        CopyTextButton(content: "Copy me!")
            .previewLayout(.sizeThatFits)
    }
}
