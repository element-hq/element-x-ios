//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

struct MessageTextTests {
    @Test
    func invalidatingAttachmentsKeepsTheText() async throws {
        let window = try makeWindow(trailingReservedSize: CGSize(width: 60, height: 16))
        defer { window.isHidden = true }
        let textView = try #require(firstMessageTextView(in: window))
        let initialText = try #require(textView.attributedText)
        
        textView.invalidateTextAttachmentsDisplay()
        try await Task.sleep(for: .milliseconds(200))
        window.layoutIfNeeded()
        
        #expect(textView.attributedText == initialText)
    }
    
    // MARK: - Helpers
    
    private func makeWindow(trailingReservedSize: CGSize) throws -> UIWindow {
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        var attributedString = try #require(attributedStringBuilder.fromHTML("Hello <a href=\"https://matrix.to/#/@alice:matrix.org\">Alice</a>"))
        var defaultAttributes = AttributeContainer()
        defaultAttributes.font = UIFont.preferredFont(forTextStyle: .body)
        attributedString.mergeAttributes(defaultAttributes, mergePolicy: .keepCurrent)
        let windowScene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: MessageText(attributedString: attributedString,
                                                                              trailingReservedSize: trailingReservedSize))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return window
    }
    
    private func firstMessageTextView(in view: UIView) -> MessageTextView? {
        if let textView = view as? MessageTextView {
            return textView
        }
        return view.subviews.lazy.compactMap(firstMessageTextView).first
    }
}
