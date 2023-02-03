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
    var blockquoteCoalescedComponents: [AttributedStringBuilderComponent] {
        runs[\.blockquote].map { value, range in
            var attributedString = AttributedString(self[range])
            
            // Remove trailing new lines if any
            if attributedString.characters.last?.isNewline ?? false,
               let range = attributedString.range(of: "\n", options: .backwards, locale: nil) {
                attributedString.removeSubrange(range)
            }
            
            let isBlockquote = value != nil
            /// This is a temporary workaround until replies are retrieved from the SDK.
            let isReply = isBlockquote && attributedString.characters.starts(with: "In reply to @")
            
            return AttributedStringBuilderComponent(attributedString: attributedString, isBlockquote: isBlockquote, isReply: isReply)
        }
    }
}
