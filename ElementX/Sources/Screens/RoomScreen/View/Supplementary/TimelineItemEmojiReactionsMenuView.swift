//
// Copyright 2022 New Vector Ltd
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

import SwiftUI

struct TimelineItemEmojiReactionsMenuView: View {
    private let emojis = ["👍🏼", "👎🏼", "😄", "🙏🏼", "😇"]
    
    var onMoreEmojisSelected: (() -> Void)?
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                }
            }
            .padding(10)
            .background(.gray)
            .cornerRadius(15)
            HStack(spacing: 10) {
                Text("➕")
            }
            .padding(10)
            .background(.gray)
            .cornerRadius(15)
            .onTapGesture {
                onMoreEmojisSelected?()
            }
        }
    }
}

struct TimelineItemEmojiReactionsMenu_Previews: PreviewProvider {
    static var previews: some View {
        TimelineItemEmojiReactionsMenuView(onMoreEmojisSelected: nil)
    }
}
