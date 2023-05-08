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

extension AttributedString {
    var formattedComponents: [AttributedStringBuilderComponent] {
        runs[\.blockquote].map { value, range in
            var attributedString = AttributedString(self[range])
            
            // Remove trailing new lines if any
            if attributedString.characters.last?.isNewline ?? false,
               let range = attributedString.range(of: "\n", options: .backwards, locale: nil) {
                attributedString.removeSubrange(range)
            }
            
            let isBlockquote = value != nil
            
            return AttributedStringBuilderComponent(attributedString: attributedString, isBlockquote: isBlockquote)
        }
    }
    
    /// Replaces the specified placeholder with the a string that links to the specified URL.
    /// - Parameters:
    ///   - linkPlaceholder: The text in the string that will be replaced. Make sure this is unique within the string.
    ///   - string: The text for the link that will be substituted into the placeholder.
    ///   - url: The URL that the link should open.
    mutating func replace(_ linkPlaceholder: String, with string: String, asLinkTo url: URL) {
        guard let range = range(of: linkPlaceholder) else {
            MXLog.failure("Failed to find the link placeholder to be replaced.")
            return
        }
        
        // Replace the placeholder with a link.
        var replacement = AttributedString(string)
        replacement.link = url
        replaceSubrange(range, with: replacement)
    }
}
