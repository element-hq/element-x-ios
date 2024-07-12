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
                            imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

struct GlobalSearchScreenListRow_Previews: PreviewProvider, TestablePreview {
    static let viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                       imageProvider: MockMediaProvider())
    
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
