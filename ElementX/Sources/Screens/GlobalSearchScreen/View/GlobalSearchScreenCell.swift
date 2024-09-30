//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct GlobalSearchScreenListRow: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: GlobalSearchRoom
    let context: GlobalSearchScreenViewModel.Context
    
    var body: some View {
        ZStack { // The list row swallows listRowBackgrounds for some reason
            ListRow(label: .avatar(title: room.name,
                                   description: room.alias ?? room.id,
                                   icon: avatar),
                    kind: .label)
        }
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .messageForwarding),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

struct GlobalSearchScreenListRow_Previews: PreviewProvider, TestablePreview {
    static let viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                       mediaProvider: MockMediaProvider())
    
    static var previews: some View {
        List {
            GlobalSearchScreenListRow(room: .init(id: "123",
                                                  name: "Tech central",
                                                  alias: "The best place in the whole wide world",
                                                  avatar: .room(id: "123",
                                                                name: "Tech central",
                                                                avatarURL: .picturesDirectory)),
                                      context: viewModel.context)
        }
    }
}
