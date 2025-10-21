//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import HTMLParser
import SwiftUI

extension HTMLParserStyle {
    static let elementX = HTMLParserStyle(textColor: UIColor.label,
                                          linkColor: UIColor.link,
                                          codeBlockStyle: BlockStyle(backgroundColor: UIColor.compound._bgCodeBlock,
                                                                     borderColor: UIColor.compound.borderInteractiveSecondary,
                                                                     borderWidth: 1.0,
                                                                     cornerRadius: 2.0,
                                                                     padding: BlockStyle.Padding(horizontal: 10, vertical: 12),
                                                                     type: .background),
                                          quoteBlockStyle: BlockStyle(backgroundColor: UIColor.compound.iconTertiary,
                                                                      borderColor: UIColor.compound.borderInteractiveSecondary,
                                                                      borderWidth: 0.0,
                                                                      cornerRadius: 0.0,
                                                                      padding: BlockStyle.Padding(horizontal: 25, vertical: 12),
                                                                      type: .side(offset: 5, width: 4)))
}
