//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TimelineTextSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let attributedString: AttributedString

    var body: some View {
        ElementNavigationStack {
            ScrollView {
                FormattedBodyText(attributedString: attributedString, selectionMode: .enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .navigationTitle(UntranslatedL10n.actionSelectText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarButton(role: .close) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

struct TimelineTextSelectionView_Previews: PreviewProvider, TestablePreview {
    static let attributedStringBuilder = AttributedStringBuilder(cacheKey: "TimelineTextSelectionView", mentionBuilder: MentionBuilder())

    static var previews: some View {
        if let attributedString = attributedStringBuilder.fromHTML("""
        <p>Select any part of this message, including <a href="https://matrix.org">links</a> and mentions such as @alice:matrix.org.</p>
        <blockquote>A quoted message with right-to-left text: مرحبا بالعالم</blockquote>
        <pre><code>let message = "Hello, Matrix!"</code></pre>
        """) {
            TimelineTextSelectionView(attributedString: attributedString)
                .environmentObject(TimelineViewModel.mock.context)
        }
    }
}
