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

struct StartChatSuggestedUserCell: View {
    let user: RoomMemberProxyProtocol
    let imageProvider: ImageProviderProtocol?
    
    var body: some View {
        HStack(spacing: 13) {
            LoadableAvatarImage(url: user.avatarURL,
                                name: user.displayName,
                                contentID: user.userID,
                                avatarSize: .user(on: .home),
                                imageProvider: imageProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                // covers both nil and empty state
                let displayName = user.displayName ?? ""
                Text(displayName.isEmpty ? user.userID : displayName)
                    .font(.element.title3)
                    .foregroundColor(.element.primaryContent)
                if !displayName.isEmpty {
                    Text(user.userID)
                        .font(.element.subheadline)
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
