//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum Redactor {
    private static let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    private static let urlPattern = #"https?://[^\s,\]\)]+"#
    private static let matrixIDPattern = #"@[A-Za-z0-9._=/+-]+:[A-Za-z0-9.-]+"#

    static func redact(_ text: String) -> String {
        var result = text
        result = redactPattern(matrixIDPattern, in: result, replacement: "<redacted-matrix-id>")
        result = redactPattern(emailPattern, in: result, replacement: "<redacted-email>")
        result = redactPattern(urlPattern, in: result, replacement: "<redacted-url>")
        return result
    }

    // MARK: - Private

    private static func redactPattern(_ pattern: String, in text: String, replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}
