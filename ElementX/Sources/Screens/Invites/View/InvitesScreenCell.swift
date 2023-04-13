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
struct InvitesScreenCell: View {
    let invite: Invite
    let imageProvider: ImageProviderProtocol?
    let acceptAction: () -> Void
    let declineAction: () -> Void
    
    private let verticalInsets = 16.0
    
    var body: some View {
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
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.element.headline)
                .foregroundColor(.element.primaryContent)
            
            if let subtitle {
                Text(subtitle)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textPlaceholder)
            }
            
            inviterView
            
            buttons
                .padding(.top, 10)
        }
    }
    
    @ViewBuilder
    private var inviterView: some View {
        if let invitedText = attributedInviteText, let name = invite.inviter?.displayName {
            HStack {
                LoadableAvatarImage(url: invite.inviter?.avatarURL,
                                    name: name,
                                    contentID: name,
                                    avatarSize: .custom(16),
                                    imageProvider: imageProvider)
                
                Text(invitedText)
            }
            .padding(.top, 4)
        }
    }
    
    private var buttons: some View {
        HStack(spacing: 12) {
            Button(L10n.actionDecline, action: declineAction)
                .buttonStyle(.elementCapsule)
            
            Button(L10n.actionAccept, action: acceptAction)
                .buttonStyle(.elementCapsuleProminent)
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.element.quinaryContent)
            .frame(height: 1 / UIScreen.main.scale)
    }
    
    private var mainAvatarURL: URL? {
        invite.isDirect ? invite.inviter?.avatarURL : invite.roomDetails.avatarURL
    }
    
    private var title: String {
        invite.roomDetails.name
    }
    
    private var subtitle: String? {
        invite.isDirect ? invite.inviter?.userID : invite.roomDetails.canonicalAlias
    }
    
    private var attributedInviteText: AttributedString? {
        guard invite.roomDetails.isDirect == false, let inviterName = invite.inviter?.displayName else {
            return nil
        }
        
        let text = L10n.screenInvitesInvitedYou(inviterName)
        var attributedString = AttributedString(text)
        attributedString.font = .compound.bodyMD
        attributedString.foregroundColor = .compound.textPlaceholder
        if let range = attributedString.range(of: inviterName) {
            attributedString[range].foregroundColor = .compound.textPrimary
        }
        return attributedString
    }
}

struct InvitesScreenCell_Previews: PreviewProvider {
    static var previews: some View {
        InvitesScreenCell(invite: .dm, imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
            .previewDisplayName("Direct room")
        
        InvitesScreenCell(invite: .room(alias: nil), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
            .previewDisplayName("Default room")
        
        InvitesScreenCell(invite: .room(alias: "#footest:somewhere.org"), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
            .previewDisplayName("Aliased room")
    }
}

@MainActor
private extension Invite {
    static var dm: Invite {
        let dmRoom = RoomSummaryDetails(id: "@someone:somewhere.com",
                                        name: "Some Guy",
                                        isDirect: true,
                                        avatarURL: nil,
                                        lastMessage: nil,
                                        lastMessageFormattedTimestamp: nil,
                                        unreadNotificationCount: 0,
                                        canonicalAlias: "#footest:somewhere.org")
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Jack"
        inviter.userID = "@jack:somewhere.com"
        
        return .init(roomDetails: dmRoom, inviter: inviter)
    }
    
    static func room(alias: String?) -> Invite {
        let dmRoom = RoomSummaryDetails(id: "@someone:somewhere.com",
                                        name: "Awesome Room",
                                        isDirect: false,
                                        avatarURL: nil,
                                        lastMessage: nil,
                                        lastMessageFormattedTimestamp: nil,
                                        unreadNotificationCount: 0,
                                        canonicalAlias: alias)
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Luca"
        inviter.userID = "@jack:somewhere.com"
        inviter.avatarURL = nil
        
        return .init(roomDetails: dmRoom, inviter: inviter)
    }
}
