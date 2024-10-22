//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct AvatarHeaderView<Footer: View>: View {
    private enum AvatarInfo {
        case room(RoomAvatar)
        case user(UserProfileProxy)
    }
    
    private enum Badge: Hashable {
        case encrypted(Bool)
        case `public`
        case verified
    }
    
    private let avatarInfo: AvatarInfo
    private let title: String
    private let subtitle: String?
    private let badges: [Badge]
    
    private let avatarSize: AvatarSize
    private let mediaProvider: MediaProviderProtocol?
    private var onAvatarTap: ((URL) -> Void)?
    @ViewBuilder private var footer: () -> Footer
    
    init(room: RoomDetails,
         avatarSize: AvatarSize,
         mediaProvider: MediaProviderProtocol? = nil,
         onAvatarTap: ((URL) -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        avatarInfo = .room(room.avatar)
        title = room.name ?? room.id
        subtitle = room.canonicalAlias
        
        self.avatarSize = avatarSize
        self.mediaProvider = mediaProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        
        var badges = [Badge]()
        badges.append(.encrypted(room.isEncrypted))
//        if room.isPublic {
//            badges.append(.public)
//        }
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
         avatarSize: AvatarSize,
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
         avatarSize: AvatarSize,
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
    
    private var badgesStack: some View {
        HStack(spacing: 8) {
            ForEach(badges, id: \.self) { badge in
                switch badge {
                case .encrypted(true):
                    BadgeLabel(title: L10n.screenRoomDetailsBadgeEncrypted,
                               icon: \.lockSolid,
                               isHighlighted: true)
                case .encrypted(false):
                    BadgeLabel(title: L10n.screenRoomDetailsBadgeNotEncrypted,
                               icon: \.lockOff,
                               isHighlighted: false)
                case .public:
                    BadgeLabel(title: L10n.screenRoomDetailsBadgePublic,
                               icon: \.public,
                               isHighlighted: false)
                case .verified:
                    BadgeLabel(title: L10n.commonVerified,
                               icon: \.verified,
                               isHighlighted: true)
                }
            }
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
        case .user(let userProfile):
            LoadableAvatarImage(url: userProfile.avatarURL,
                                name: userProfile.displayName,
                                contentID: userProfile.userID,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider)
        }
    }
    
    var body: some View {
        VStack(spacing: 8.0) {
            avatar
            
            Spacer()
                .frame(height: 9)
            
            Text(title)
                .foregroundColor(.compound.textPrimary)
                .font(.zero.headingMDBold)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            
//            if let subtitle {
//                Text(subtitle)
//                    .foregroundColor(.compound.textSecondary)
//                    .font(.zero.bodyLG)
//                    .multilineTextAlignment(.center)
//                    .textSelection(.enabled)
//            }
            
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
                                                       avatarURL: .picturesDirectory),
                                         canonicalAlias: "#test:matrix.org",
                                         isEncrypted: true,
                                         isPublic: true),
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
