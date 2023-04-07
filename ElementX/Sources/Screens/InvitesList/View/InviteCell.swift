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

@MainActor
struct InviteCell: View {
    let invite: Invite
    let imageProvider: ImageProviderProtocol?
    
    private let verticalInsets = 16.0
    
    var body: some View {
        #warning("cleanup")
        HStack(alignment: .top, spacing: 16) {
            LoadableAvatarImage(url: mainAvatarURL,
                                name: title,
                                contentID: invite.roomDetails.id,
                                avatarSize: .custom(52),
                                imageProvider: imageProvider)
                .accessibilityHidden(true)
            
            mainContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, verticalInsets)
                .overlay(alignment: .bottom) {
                    separator
                }
        }
        .padding(.top, verticalInsets)
        .padding(.horizontal, 12)
    }
    
    // MARK: - Private
    
    private var mainAvatarURL: URL? {
        invite.isDirect ? invite.inviter?.avatarURL : invite.roomDetails.avatarURL
    }
    
    private var title: String? {
        invite.isDirect ? invite.inviter?.displayName : invite.roomDetails.name
    }
    
    private var subtitle: String? {
        invite.isDirect ? invite.inviter?.userID : invite.roomDetails.id
    }
    
    #warning("cleanup")
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title ?? "FIXME")
                .font(.element.title3)
                .foregroundColor(.element.primaryContent)
            
            if let subtitle {
                Text(subtitle)
                    .font(.element.subheadline)
                    .foregroundColor(.element.tertiaryContent)
            }
            
            if !invite.isDirect, let name = invite.inviter?.displayName {
                HStack {
                    if let inviterAvatar = invite.inviter?.avatarURL {
                        LoadableAvatarImage(url: inviterAvatar,
                                            name: name,
                                            contentID: name,
                                            avatarSize: .custom(16),
                                            imageProvider: imageProvider)
                    }
                 
                    #warning("Localize")
                    Text("\(name) invited you")
                        .font(.compound.bodyMD)
                }
            }
            
            buttons
                .padding(.top, 8)
        }
    }
    
    #warning("Localize")
    private var buttons: some View {
        HStack(spacing: 12) {
            Button("Decline") { }
                .buttonStyle(.elementCapsule)
            
            Button("Accept") { }
                .buttonStyle(.elementCapsuleProminent)
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.element.quinaryContent)
            .frame(height: 1 / UIScreen.main.scale)
    }
}

struct InviteCell_Previews: PreviewProvider {
    static var previews: some View {
        let roomDetails = RoomSummaryDetails(id: "some id", name: "some name", isDirect: false, avatarURL: nil, lastMessage: nil, lastMessageFormattedTimestamp: nil, unreadNotificationCount: 0)
        InviteCell(invite: .init(roomDetails: roomDetails), imageProvider: MockMediaProvider())
    }
}
