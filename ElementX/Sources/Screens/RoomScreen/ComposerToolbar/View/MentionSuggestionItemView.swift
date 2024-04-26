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

import SwiftUI

struct MentionSuggestionItemView: View {
    let imageProvider: ImageProviderProtocol?
    let item: MentionSuggestionItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            LoadableAvatarImage(url: item.avatarURL,
                                name: item.displayName,
                                contentID: item.id,
                                avatarSize: .user(on: .suggestions),
                                imageProvider: imageProvider)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.displayName ?? item.id)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                if item.displayName != nil {
                    Text(item.id)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct MentionSuggestionItemView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MockMediaProvider()
    
    static var previews: some View {
        MentionSuggestionItemView(imageProvider: mockMediaProvider, item: .init(id: "test", displayName: "Test", avatarURL: URL.documentsDirectory, range: .init()))
        MentionSuggestionItemView(imageProvider: mockMediaProvider, item: .init(id: "test2", displayName: nil, avatarURL: nil, range: .init()))
    }
}
