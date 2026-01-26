//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct AttributedStringBuilderComponent: Hashable, Identifiable {
    enum ComponentType {
        case plainText
        case blockquote
        case codeBlock
    }
    
    let id: String
    let attributedString: AttributedString
    let type: ComponentType
}

protocol AttributedStringBuilderProtocol {
    func fromPlain(_ string: String?) -> AttributedString?
    
    func fromHTML(_ htmlString: String?) -> AttributedString?
    
    func addMatrixEntityPermalinkAttributesTo(_ attributedString: NSMutableAttributedString)
}
