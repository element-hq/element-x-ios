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

struct InviteUsersScreenSelectedItem: View {
    let user: UserProfileProxy
    let imageProvider: ImageProviderProtocol?
    let dismissAction: () -> Void
    
    @ScaledMetric private var buttonSize: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 0) {
            avatar
            
            Text(user.displayName ?? user.userID)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Private
    
    var avatar: some View {
        LoadableAvatarImage(url: user.avatarURL,
                            name: user.displayName,
                            contentID: user.userID,
                            avatarSize: .user(on: .inviteUsers),
                            imageProvider: imageProvider)
            .overlay(alignment: .topTrailing) {
                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: buttonSize, height: buttonSize)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.element.systemPrimaryBackground, Color.compound.iconPrimary)
                }
            }
    }
}

struct InviteUsersScreenSelectedItem_Previews: PreviewProvider {
    static let people: [UserProfileProxy] = [.mockAlice, .mockVerbose]
    
    static var previews: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 28) {
                ForEach(Self.people, id: \.userID) { user in
                    InviteUsersScreenSelectedItem(user: user, imageProvider: MockMediaProvider(), dismissAction: { })
                        .frame(width: 72)
                }
            }
        }
    }
}
