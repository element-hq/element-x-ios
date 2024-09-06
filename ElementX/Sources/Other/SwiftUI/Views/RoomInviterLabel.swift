//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct RoomInviterDetails: Equatable {
    let id: String
    let displayName: String?
    let avatarURL: URL?
    
    let attributedInviteText: AttributedString
    
    init(member: RoomMemberProxyProtocol) {
        id = member.userID
        displayName = member.displayName
        avatarURL = member.avatarURL
        
        let nameOrLocalPart = if let displayName = member.displayName {
            displayName
        } else {
            String(member.userID.dropFirst().prefix { $0 != ":" })
        }
        
        // Pre-compute the attributed string.
        let placeholder = "{displayname}"
        var string = AttributedString(L10n.screenInvitesInvitedYou(placeholder, id))
        var displayNameString = AttributedString(nameOrLocalPart)
        displayNameString.bold()
        displayNameString.foregroundColor = .compound.textPrimary
        string.replace(placeholder, with: displayNameString)
        attributedInviteText = string
    }
}

struct RoomInviterLabel: View {
    let inviter: RoomInviterDetails
    
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            LoadableAvatarImage(url: inviter.avatarURL,
                                name: inviter.displayName,
                                contentID: inviter.id,
                                avatarSize: .custom(16),
                                mediaProvider: mediaProvider)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.8 }
                .accessibilityHidden(true)
            
            Text(inviter.attributedInviteText)
        }
    }
}

// MARK: - Previews

struct RoomInviterLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 10) {
            RoomInviterLabel(inviter: .init(member: RoomMemberProxyMock.mockAlice),
                             mediaProvider: MockMediaProvider())
            RoomInviterLabel(inviter: .init(member: RoomMemberProxyMock.mockDan),
                             mediaProvider: MockMediaProvider())
            RoomInviterLabel(inviter: .init(member: RoomMemberProxyMock.mockNoName),
                             mediaProvider: MockMediaProvider())
            RoomInviterLabel(inviter: .init(member: RoomMemberProxyMock.mockCharlie),
                             mediaProvider: MockMediaProvider())
                .foregroundStyle(.compound.textPrimary)
        }
        .font(.compound.bodyMD)
        .foregroundStyle(.compound.textSecondary)
    }
}
