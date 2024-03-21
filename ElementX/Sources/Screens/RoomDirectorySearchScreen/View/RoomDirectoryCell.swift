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
    
    // If no topic is available we show the room id but only if the room ID isn't already shown as the title
    var description: String? {
        if let topic = result.topic {
            return topic
        }
        
        if result.name == nil {
            return nil
        }
        
        return result.roomID
    }

    var body: some View {
        ListRow(label: .avatar(title: result.name ?? result.roomID,
                               description: description,
                               icon: avatar), kind: .label)
    }
    
    @ViewBuilder
    var avatar: some View {
        LoadableAvatarImage(url: result.avatarURL,
                            name: result.name,
                            contentID: result.id,
                            avatarSize: .room(on: .roomDirectorySearch),
                            imageProvider: imageProvider)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct RoomDirectorySearchCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomDirectorySearchCell(result: .init(roomID: "tes_id", name: "Test title", topic: "test description", avatarURL: nil, canBeJoined: false), imageProvider: MockMediaProvider())
    }
}
