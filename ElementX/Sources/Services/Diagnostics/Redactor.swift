//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Interfaces

protocol Redacting {
    func redact(_ text: String) -> String
}

// MARK: - Implementations

final class Redactor: Redacting {
    // MARK: - Private Properties

    private let replacement: String
    private let rules: [NSRegularExpression?]

    // MARK: - Initializers

    init(replacement: String = "<redacted>") {
        self.replacement = replacement
        rules = [
            Redactor.makeRegex(pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.caseInsensitive]),
            Redactor.makeRegex(pattern: #"https?://[^\s]+"#, options: [.caseInsensitive]),
            Redactor.makeRegex(pattern: #"@[^\s:]+:[^\s]+"#, options: [])
        ]
    }

    // MARK: - Public Methods

    func redact(_ text: String) -> String {
        var redactedText = text
        rules.forEach { regex in
            guard let regex else { return }
            let range = NSRange(redactedText.startIndex..<redactedText.endIndex, in: redactedText)
            redactedText = regex.stringByReplacingMatches(in: redactedText, range: range, withTemplate: replacement)
        }
        return redactedText
    }

    // MARK: - Private Methods

    private static func makeRegex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            assertionFailure("Invalid redaction regex: \(pattern)")
            return nil
        }
    }
}
