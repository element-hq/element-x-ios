//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// NSRegularExpressions work internally on NSStrings, we need to be careful how we build the ranges for extended grapheme clusters https://stackoverflow.com/a/27880748/730924
extension NSRegularExpression {
    func matches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        matches(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
    
    func firstMatch(in string: String, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        firstMatch(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
}
