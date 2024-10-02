//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct AttributedStringBuilderComponent: Hashable, Identifiable {
    let id: String
    let attributedString: AttributedString
    let isBlockquote: Bool
}

protocol AttributedStringBuilderProtocol {
    func fromPlain(_ string: String?) -> AttributedString?
    
    func fromHTML(_ htmlString: String?) -> AttributedString?
    
    func detectPermalinks(_ attributedString: NSMutableAttributedString)
}
