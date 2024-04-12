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

import Combine
import Foundation
import SwiftUI

struct RoomHeaderView: View {
    let roomID: String
    let roomName: String
    let avatarURL: URL?
    
    let imageProvider: ImageProviderProtocol?
    
    var body: some View {
        HStack(spacing: 12) {
            roomAvatar
                .accessibilityHidden(true)
            Text(roomName)
                .font(.compound.bodyLGSemibold)
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
        }
        // Leading align whilst using the principal toolbar position.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var roomAvatar: some View {
        LoadableAvatarImage(url: avatarURL,
                            name: roomName,
                            contentID: roomID,
                            avatarSize: .room(on: .timeline),
                            imageProvider: imageProvider)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.avatar)
    }
}

struct RoomHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomHeaderView(roomID: "1",
                       roomName: "Some Room name",
                       avatarURL: URL.picturesDirectory,
                       imageProvider: MockMediaProvider())
            .previewLayout(.sizeThatFits)
            .padding()
        
        RoomHeaderView(roomID: "1",
                       roomName: "Some Room name",
                       avatarURL: nil,
                       imageProvider: MockMediaProvider())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
