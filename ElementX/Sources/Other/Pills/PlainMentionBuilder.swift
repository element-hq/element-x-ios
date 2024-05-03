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

// In the future we might use this to do some customisation in what is plain text used to represent mentions.
struct PlainMentionBuilder: MentionBuilderProtocol {
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange) { }
    
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?) {
        guard !attributedString.attributedSubstring(from: range).string.hasPrefix("@") else {
            return
        }
        attributedString.insert(NSAttributedString(string: "@"), at: range.location)
    }
}
