//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol Redacting {
    func redact(_ text: String) -> String
}

struct Redactor: Redacting {
    func redact(_ text: String) -> String {
        Self.replacements.reduce(text) { partialResult, replacement in
            replacement.expression.stringByReplacingMatches(in: partialResult,
                                                            options: [],
                                                            range: NSRange(partialResult.startIndex..., in: partialResult),
                                                            withTemplate: replacement.replacement)
        }
    }
    
    private struct Replacement {
        let expression: NSRegularExpression
        let replacement: String
    }
    
    private static let replacements = [
        Replacement(expression: try! NSRegularExpression(pattern: #"@[A-Za-z0-9._=\/\-]+:[A-Za-z0-9.\-]+(?:\:[0-9]+)?"#),
                    replacement: "[redacted matrix id]"),
        Replacement(expression: try! NSRegularExpression(pattern: #"\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b"#,
                                                         options: [.caseInsensitive]),
                    replacement: "[redacted email]"),
        Replacement(expression: try! NSRegularExpression(pattern: #"\b(?:https?|ftp)://[^\s]+"#,
                                                         options: [.caseInsensitive]),
                    replacement: "[redacted url]")
    ]
}
