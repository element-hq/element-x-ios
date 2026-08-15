//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct AttributedStringBuilderComponent: Hashable, Identifiable {
    enum Kind: Hashable {
        case text
        case blockquote(children: [AttributedStringBuilderComponent])
        case codeBlock
    }
    
    /// Identifier for the `Identifiable` conformance, allows edits to the `FormattedBodyText` to animate seamlessly
    let id: String
    /// The component's content. For a blockquote this is everything inside it,
    /// whilst its `children` carry the same content as structured components.
    let attributedString: AttributedString
    let kind: Kind
    /// How many list levels deep this block sits (0 outside of lists), so it
    /// can be indented under its item's bullet.
    var listIndent = 0
    
    var isText: Bool {
        if case .text = kind { return true }
        return false
    }
}

nonisolated protocol AttributedStringBuilderProtocol: Sendable {
    func fromPlain(_ string: String?) -> AttributedString?
    
    func fromHTML(_ htmlString: String?) -> AttributedString?
    
    func addMatrixEntityPermalinkAttributesTo(_ attributedString: NSMutableAttributedString)
}
