//
// Copyright 2024 New Vector Ltd
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

import Compound
import SwiftUI

struct RoomDirectorySearchCell: View {
    let result: RoomDirectorySearchResult
    let imageProvider: ImageProviderProtocol?
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ListRow(label: .avatar(title: result.name ?? result.roomID,
                               description: result.topic,
                               icon: avatar), kind: .label)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            LoadableAvatarImage(url: result.avatarURL,
                                name: result.name,
                                contentID: result.id,
                                avatarSize: .room(on: .roomDirectorySearch),
                                imageProvider: imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct RoomDirectorySearchCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomDirectorySearchCell(result: .init(roomID: "tes_id", name: "Test title", topic: "test description", avatarURL: nil, canBeJoined: false), imageProvider: MockMediaProvider())
    }
}
