//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// NSRegularExpressions work internally on NSStrings, we need to be careful how we build the ranges for extended grapheme clusters https://stackoverflow.com/a/27880748/730924
extension NSRegularExpression {
    func enumerateMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], using block: (NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateMatches(in: string, options: options, range: .init(location: 0, length: (string as NSString).length), using: block)
    }
    
    func matches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        matches(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
    
    func numberOfMatches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> Int {
        numberOfMatches(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
    
    func firstMatch(in string: String, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        firstMatch(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
    
    func rangeOfFirstMatch(in string: String, options: NSRegularExpression.MatchingOptions = []) -> NSRange {
        rangeOfFirstMatch(in: string, options: options, range: .init(location: 0, length: (string as NSString).length))
    }
}
