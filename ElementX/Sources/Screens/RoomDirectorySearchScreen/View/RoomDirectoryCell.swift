//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomDirectorySearchCell: View {
    let result: RoomDirectorySearchResult
    let mediaProvider: MediaProviderProtocol?
    let joinAction: () -> Void
        
    private var description: String? {
        if let topic = result.topic {
            return topic
        }
        
        if result.name != nil, let alias = result.alias {
            return alias
        } else if result.name == nil, result.alias == nil {
            return nil
        }
        
        return result.id
    }

    var body: some View {
        ListRow(label: .avatar(title: result.name ?? result.alias ?? result.id,
                               description: description,
                               icon: avatar),
                kind: result.canBeJoined ? .navigationLink(action: joinAction) : .label)
    }
    
    private var avatar: some View {
        RoomAvatarImage(avatar: result.avatar,
                        avatarSize: .room(on: .roomDirectorySearch),
                        mediaProvider: mediaProvider)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct RoomDirectorySearchCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        List {
            RoomDirectorySearchCell(result: .init(id: "!test_id_1:matrix.org",
                                                  alias: "#test:example.com",
                                                  name: "Test title",
                                                  topic: "test description",
                                                  avatar: .room(id: "!test_id_1:matrix.org",
                                                                name: "Test title",
                                                                avatarURL: nil),
                                                  canBeJoined: true),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_2:matrix.org",
                                                  alias: "#test:example.com",
                                                  name: nil,
                                                  topic: "test description",
                                                  avatar: .room(id: "!test_id_2:matrix.org",
                                                                name: nil,
                                                                avatarURL: nil),
                                                  canBeJoined: true),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_3:example.com",
                                                  alias: "#test_no_topic:example.com",
                                                  name: "Test title no topic",
                                                  topic: nil,
                                                  avatar: .room(id: "!test_id_3:example.com",
                                                                name: "Test title no topic",
                                                                avatarURL: nil),
                                                  canBeJoined: true),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_4:example.com",
                                                  alias: "#test_no_topic:example.com",
                                                  name: nil,
                                                  topic: nil,
                                                  avatar: .room(id: "!test_id_4:example.com",
                                                                name: nil,
                                                                avatarURL: nil),
                                                  canBeJoined: true),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_5:example.com",
                                                  alias: nil,
                                                  name: "Test title no alias",
                                                  topic: nil,
                                                  avatar: .room(id: "!test_id_5:example.com",
                                                                name: "Test title no alias",
                                                                avatarURL: nil),
                                                  canBeJoined: false),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_6:example.com",
                                                  alias: nil,
                                                  name: "Test title no alias",
                                                  topic: "Topic",
                                                  avatar: .room(id: "!test_id_6:example.com",
                                                                name: "Test title no alias",
                                                                avatarURL: nil),
                                                  canBeJoined: false),
                                    mediaProvider: MockMediaProvider()) { }
            
            RoomDirectorySearchCell(result: .init(id: "!test_id_7:example.com",
                                                  alias: nil,
                                                  name: nil,
                                                  topic: "Topic",
                                                  avatar: .room(id: "!test_id_7:example.com",
                                                                name: nil,
                                                                avatarURL: nil),
                                                  canBeJoined: false),
                                    mediaProvider: MockMediaProvider()) { }
            RoomDirectorySearchCell(result: .init(id: "!test_id_8:example.com",
                                                  alias: nil,
                                                  name: nil,
                                                  topic: nil,
                                                  avatar: .room(id: "!test_id_8:example.com",
                                                                name: nil,
                                                                avatarURL: nil),
                                                  canBeJoined: false),
                                    mediaProvider: MockMediaProvider()) { }
        }
        .compoundList()
    }
}
