//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Flow
import SwiftUI

struct AvatarHeaderView<Footer: View>: View {
    private enum AvatarInfo {
        case room(RoomAvatar)
        case user(UserProfileProxy)
    }
    
    private enum Badge: Hashable {
        case encrypted(Bool)
        case historySharingState(RoomHistorySharingState)
        case `public`
        case verified
    }
    
    private let avatarInfo: AvatarInfo
    private let title: String
    private let subtitle: String?
    private let badges: [Badge]
    
    private let avatarSize: Avatars.Size
    private let mediaProvider: MediaProviderProtocol?
    private var onAvatarTap: ((URL) -> Void)?
    @ViewBuilder private var footer: () -> Footer
    
    init(room: RoomDetails,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        avatarInfo = .room(room.avatar)
        title = room.name ?? room.id
        
        if let roomAlias = room.canonicalAlias {
            subtitle = roomAlias
        } else if room.isDirect, case let .heroes(heroes) = room.avatar, heroes.count == 1 {
            subtitle = heroes[0].userID
        } else {
            subtitle = nil
        }
        
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        
        var badges = [Badge]()
        badges.append(.encrypted(room.isEncrypted))
        if room.isPublic {
            badges.append(.public)
        }
        if let state = room.historySharingState {
            badges.append(.historySharingState(state))
        }
        self.badges = badges
    }
    
    init(accountOwner: RoomMemberDetails,
         dmRecipient: RoomMemberDetails,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        let dmRecipientProfile = UserProfileProxy(member: dmRecipient)
        avatarInfo = .room(.heroes([dmRecipientProfile, UserProfileProxy(member: accountOwner)]))
        title = dmRecipientProfile.displayName ?? dmRecipientProfile.userID
        subtitle = dmRecipientProfile.displayName == nil ? nil : dmRecipientProfile.userID
        
        avatarSize = .user(on: .dmDetails)
        self.mediaProvider = mediaProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        // In EL-X a DM is by definition always encrypted
        badges = [.encrypted(true)]
    }
    
    init(member: RoomMemberDetails,
         isVerified: Bool = false,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        let profile = UserProfileProxy(member: member)
        
        self.init(user: profile,
                  isVerified: isVerified,
                  avatarSize: avatarSize,
                  mediaProvider: mediaProvider,
                  onAvatarTap: onAvatarTap,
                  footer: footer)
    }
    
    init(user: UserProfileProxy,
         isVerified: Bool,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        avatarInfo = .user(user)
        title = user.displayName ?? user.userID
        subtitle = user.displayName == nil ? nil : user.userID
        
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        badges = isVerified ? [.verified] : []
    }
    
    /// Initialises the view by using the sender,
    /// only to be used when a room member has not been loaded yet.
    init(sender: TimelineItemSender,
         avatarSize: Avatars.Size,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        let profile = UserProfileProxy(sender: sender)
        
        self.init(user: profile,
                  isVerified: false,
                  avatarSize: avatarSize,
                  mediaProvider: mediaProvider,
                  onAvatarTap: onAvatarTap,
                  footer: footer)
    }
    
    private var badgesStack: some View {
        HFlow(horizontalAlignment: .center,
              verticalAlignment: .top,
              horizontalSpacing: 8.0,
              verticalSpacing: 8.0) {
            ForEach(badges, id: \.self) { badge in
                switch badge {
                case .encrypted(true):
                    BadgeLabel(title: L10n.screenRoomDetailsBadgeEncrypted,
                               icon: \.lockSolid,
                               style: .accent)
                case .encrypted(false):
                    BadgeLabel(title: L10n.screenRoomDetailsBadgeNotEncrypted,
                               icon: \.lockOff,
                               style: .info)
                case .public:
                    BadgeLabel(title: L10n.screenRoomDetailsBadgePublic,
                               icon: \.public,
                               style: .info)
                case .verified:
                    BadgeLabel(title: L10n.commonVerified,
                               icon: \.verified,
                               style: .accent)
                case .historySharingState(.hidden):
                    BadgeLabel(title: UntranslatedL10n.cryptoHistorySharingRoomInfoHiddenBadgeContent,
                               icon: \.visibilityOff,
                               style: .info)
                case .historySharingState(.shared):
                    BadgeLabel(title: UntranslatedL10n.cryptoHistorySharingRoomInfoSharedBadgeContent,
                               icon: \.history,
                               style: .info)
                case .historySharingState(.worldReadable):
                    BadgeLabel(title: UntranslatedL10n.cryptoHistorySharingRoomInfoWorldReadableBadgeContent,
                               icon: \.userProfileSolid,
                               style: .info)
                }
            }
        }
    }
    
    private var avatarAccessibilityLabel: String {
        guard onAvatarTap != nil else {
            return L10n.a11yAvatar
        }
        switch avatarInfo {
        case .room(let roomAvatar):
            return roomAvatar.hasURL ? L10n.a11yViewAvatar : L10n.a11yAvatar
        case .user(let userProfileProxy):
            return userProfileProxy.avatarURL != nil ? L10n.a11yViewAvatar : L10n.a11yAvatar
        }
    }
    
    @ViewBuilder
    private var avatar: some View {
        switch avatarInfo {
        case .room(let roomAvatar):
            RoomAvatarImage(avatar: roomAvatar,
                            avatarSize: avatarSize,
                            mediaProvider: mediaProvider,
                            onAvatarTap: onAvatarTap)
                .accessibilityLabel(avatarAccessibilityLabel)
            
        case .user(let userProfile):
            LoadableAvatarImage(url: userProfile.avatarURL,
                                name: userProfile.displayName,
                                contentID: userProfile.userID,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider,
                                onTap: onAvatarTap)
                .accessibilityLabel(avatarAccessibilityLabel)
        }
    }
    
    var body: some View {
        VStack(spacing: 8.0) {
            avatar
            
            Spacer()
                .frame(height: 9)
            
            Text(title)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            
            if let subtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyLG)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
            
            if !badges.isEmpty {
                badgesStack
            }
            
            footer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 11,
                                  leading: 0,
                                  bottom: 11,
                                  trailing: 0))
    }
}

struct AvatarHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            AvatarHeaderView(room: .init(id: "@test:matrix.org",
                                         name: "Test Room",
                                         avatar: .room(id: "@test:matrix.org",
                                                       name: "Test Room",
                                                       avatarURL: .mockMXCAvatar),
                                         canonicalAlias: "#test:matrix.org",
                                         isEncrypted: true,
                                         isPublic: true,
                                         isDirect: false),
                             avatarSize: .room(on: .details),
                             mediaProvider: MediaProviderMock(configuration: .init())) {
                HStack(spacing: 32) {
                    ShareLink(item: "test") {
                        CompoundIcon(\.shareIos)
                    }
                    .buttonStyle(FormActionButtonStyle(title: "Test"))
                }
                .padding(.top, 32)
            }
        }
        .previewDisplayName("Room")
        
        Form {
            AvatarHeaderView(accountOwner: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockMe), dmRecipient: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockAlice),
                             mediaProvider: MediaProviderMock(configuration: .init())) {
                HStack(spacing: 32) {
                    ShareLink(item: "test") {
                        CompoundIcon(\.shareIos)
                    }
                    .buttonStyle(FormActionButtonStyle(title: "Test"))
                }
                .padding(.top, 32)
            }
        }
        .previewDisplayName("DM")
        
        VStack(spacing: 16) {
            AvatarHeaderView(member: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockAlice),
                             avatarSize: .room(on: .details),
                             mediaProvider: MediaProviderMock(configuration: .init())) { Text("") }
            
            AvatarHeaderView(member: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockBob),
                             isVerified: true,
                             avatarSize: .room(on: .details),
                             mediaProvider: MediaProviderMock(configuration: .init())) { Text("") }
            
            AvatarHeaderView(member: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockBanned[3]),
                             avatarSize: .room(on: .details),
                             mediaProvider: MediaProviderMock(configuration: .init())) { Text("") }
        }
        .padding()
        .background(Color.compound.bgSubtleSecondaryLevel0)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Members")
    }
}
