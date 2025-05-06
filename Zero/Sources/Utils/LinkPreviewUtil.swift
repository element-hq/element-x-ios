//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import Foundation

class LinkPreviewUtil {
    static let shared = LinkPreviewUtil()
    
    private init() { }
    
    func firstNonMatrixLink(from text: String?) -> String? {
        guard let text = text else {
            return nil
        }
        
        let matrixMentionRegex = #"https:\/\/matrix\.to\/#\/@[^\/\s]+"#
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let urlString = String(text[range])
            if urlString.range(of: matrixMentionRegex, options: .regularExpression) == nil {
                return urlString
            }
        }
        return nil
    }
}
