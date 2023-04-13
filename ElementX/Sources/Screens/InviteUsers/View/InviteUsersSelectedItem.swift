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

struct InviteUsersSelectedItem: View {
    let user: UserProfile
    let imageProvider: ImageProviderProtocol?
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            LoadableAvatarImage(url: user.avatarURL,
                                name: user.displayName,
                                contentID: user.userID,
                                avatarSize: .user(on: .inviteUsers),
                                imageProvider: imageProvider)
            Text(user.displayName ?? user.userID)
                .font(.element.title3)
                .foregroundColor(.element.primaryContent)
                .lineLimit(1)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: dismissAction) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.element.systemPrimaryBackground, Color.element.primaryContent)
            }
        }
    }
}

struct SelectedInvitedUserItem_Previews: PreviewProvider {
    static var previews: some View {
        InviteUsersSelectedItem(user: .mockAlice, imageProvider: MockMediaProvider(), dismissAction: { })
    }
}
