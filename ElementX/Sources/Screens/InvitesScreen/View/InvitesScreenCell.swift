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
    let invite: InvitesScreenRoomDetails
    let imageProvider: ImageProviderProtocol?
    let acceptAction: () -> Void
    let declineAction: () -> Void
    
    @ScaledMetric private var badgeSize = 12.0
    
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
                .padding(.bottom, 16)
                .padding(.trailing, 16)
                .overlay(alignment: .bottom) {
                    separator
                }
        }
        .padding(.top, 12)
        .padding(.leading, 16)
    }
    
    // MARK: - Private

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                textualContent
                    .padding(.trailing, invite.isUnread ? 0 : 16)
                
                if invite.isUnread {
                    badge
                }
            }
            
            inviterView
                .padding(.top, 6)
                .padding(.trailing, 16)
            
            buttons
                .padding(.top, 14)
                .padding(.trailing, 22)
        }
    }

    @ViewBuilder
    private var inviterView: some View {
        if let invitedText = attributedInviteText, let name = invite.inviter?.displayName {
            HStack(alignment: .firstTextBaseline) {
                LoadableAvatarImage(url: invite.inviter?.avatarURL,
                                    name: name,
                                    contentID: name,
                                    avatarSize: .custom(16),
                                    imageProvider: imageProvider)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.8 }
                
                Text(invitedText)
            }
        }
    }
    
    @ViewBuilder
    private var textualContent: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(2)
            
            if let subtitle {
                Text(subtitle)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textPlaceholder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var buttons: some View {
        HStack(spacing: 12) {
            Button(L10n.actionDecline, action: declineAction)
                .buttonStyle(.elementCapsule)
                .accessibilityIdentifier(A11yIdentifiers.invitesScreen.decline)
            
            Button(L10n.actionAccept, action: acceptAction)
                .buttonStyle(.elementCapsuleProminent)
                .accessibilityIdentifier(A11yIdentifiers.invitesScreen.accept)
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.element.quinaryContent)
            .frame(height: 1 / UIScreen.main.scale)
    }
    
    #warning("Return just `roomDetails.avatarURL` when this logic is implemented in the rust sdk")
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
        guard
            invite.roomDetails.isDirect == false,
            let inviterName = invite.inviter?.displayName,
            let inviterID = invite.inviter?.userID
        else {
            return nil
        }
        
        let text = L10n.screenInvitesInvitedYou(inviterName, inviterID)
        var attributedString = AttributedString(text)
        attributedString.font = .compound.bodyMD
        attributedString.foregroundColor = .compound.textPlaceholder
        if let range = attributedString.range(of: inviterName) {
            attributedString[range].foregroundColor = .compound.textPrimary
            attributedString[range].font = .compound.bodyMDSemibold
        }
        return attributedString
    }
    
    private var badge: some View {
        Circle()
            .frame(width: badgeSize, height: badgeSize)
            .foregroundColor(.element.brand)
    }
}

struct InvitesScreenCell_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                InvitesScreenCell(invite: .dm, imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
                
                InvitesScreenCell(invite: .room(), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
                
                InvitesScreenCell(invite: .room(isUnread: false), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
                
                InvitesScreenCell(invite: .room(alias: "#footest:somewhere.org", avatarURL: .picturesDirectory), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
                
                InvitesScreenCell(invite: .room(alias: "#footest:somewhere.org"), imageProvider: MockMediaProvider(), acceptAction: { }, declineAction: { })
                    .dynamicTypeSize(.accessibility1)
                    .previewDisplayName("Aliased room (AX1)")
            }
        }
    }
}

@MainActor
private extension InvitesScreenRoomDetails {
    static var dm: InvitesScreenRoomDetails {
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
        
        return .init(roomDetails: dmRoom, inviter: inviter, isUnread: false)
    }
    
    static func room(alias: String? = nil, avatarURL: URL? = nil, isUnread: Bool = true) -> InvitesScreenRoomDetails {
        let dmRoom = RoomSummaryDetails(id: "@someone:somewhere.com",
                                        name: "Awesome Room",
                                        isDirect: false,
                                        avatarURL: avatarURL,
                                        lastMessage: nil,
                                        lastMessageFormattedTimestamp: nil,
                                        unreadNotificationCount: 0,
                                        canonicalAlias: alias)
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Luca"
        inviter.userID = "@jack:somewhi.nl"
        inviter.avatarURL = avatarURL
        
        return .init(roomDetails: dmRoom, inviter: inviter, isUnread: isUnread)
    }
}
