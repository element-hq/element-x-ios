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
