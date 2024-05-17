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

struct AvatarHeaderView<Footer: View>: View {
    private struct AvatarInfo {
        let id: String
        let name: String?
        let avatarURL: URL?
        
        init(from room: RoomDetails) {
            id = room.id
            name = room.name
            avatarURL = room.avatarURL
        }
        
        init(from member: RoomMemberDetails) {
            id = member.id
            name = member.isBanned ? nil : member.name
            avatarURL = member.isBanned ? nil : member.avatarURL
        }
        
        init(from user: UserProfileProxy) {
            id = user.userID
            name = user.displayName
            avatarURL = user.avatarURL
        }
    }
    
    private enum Badge: Hashable {
        case encrypted(Bool)
        case `public`
    }
    
    private let mainAvatarInfo: AvatarInfo
    private let secondaryAvatarInfo: AvatarInfo?
    private let subtitle: String?
    private let badges: [Badge]
    
    private let avatarSize: AvatarSize
    private let imageProvider: ImageProviderProtocol?
    private var onAvatarTap: (() -> Void)?
    @ViewBuilder private var footer: () -> Footer
    
    init(room: RoomDetails,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        mainAvatarInfo = .init(from: room)
        secondaryAvatarInfo = nil
        subtitle = room.canonicalAlias
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        
        var badges = [Badge]()
        badges.append(.encrypted(room.isEncrypted))
        if room.isPublic {
            badges.append(.public)
        }
        self.badges = badges
    }
    
    init(accountOwner: RoomMemberDetails,
         dmRecipient: RoomMemberDetails,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        mainAvatarInfo = .init(from: dmRecipient)
        secondaryAvatarInfo = .init(from: accountOwner)
        subtitle = dmRecipient.isBanned ? nil : dmRecipient.name == nil ? nil : dmRecipient.id
        
        avatarSize = .user(on: .dmDetails)
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        // In EL-X a DM is by definition always encrypted
        badges = [.encrypted(true)]
    }
    
    init(member: RoomMemberDetails,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        mainAvatarInfo = .init(from: member)
        secondaryAvatarInfo = nil
        subtitle = member.isBanned ? nil : member.name == nil ? nil : member.id
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        badges = []
    }
    
    init(user: UserProfileProxy,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        mainAvatarInfo = .init(from: user)
        secondaryAvatarInfo = nil
        subtitle = user.displayName == nil ? nil : user.userID
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
        badges = []
    }
    
    private var badgesStack: some View {
        HStack(spacing: 8) {
            ForEach(badges, id: \.self) { badge in
                switch badge {
                case .encrypted(let isEncrypted):
                    if isEncrypted {
                        BadgeLabel(title: L10n.screenRoomDetailsBadgeEncrypted,
                                   icon: \.lockSolid,
                                   isHighlighted: true)
                    } else {
                        BadgeLabel(title: L10n.screenRoomDetailsBadgeNotEncrypted,
                                   icon: \.lockOff,
                                   isHighlighted: false)
                    }
                case .public:
                    BadgeLabel(title: L10n.screenRoomDetailsBadgePublic,
                               icon: \.public,
                               isHighlighted: false)
                }
            }
        }
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let secondaryAvatarInfo {
            ZStack {
                LoadableAvatarImage(url: mainAvatarInfo.avatarURL,
                                    name: mainAvatarInfo.name,
                                    contentID: mainAvatarInfo.id,
                                    avatarSize: avatarSize,
                                    imageProvider: imageProvider)
                    .scaledFrame(size: 120, alignment: .topTrailing)
                LoadableAvatarImage(url: secondaryAvatarInfo.avatarURL,
                                    name: secondaryAvatarInfo.name,
                                    contentID: secondaryAvatarInfo.id,
                                    avatarSize: avatarSize,
                                    imageProvider: imageProvider)
                    .mask {
                        Rectangle()
                            .fill(Color.white)
                            .overlay {
                                Circle()
                                    .inset(by: -4)
                                    .fill(Color.black)
                                    .scaledOffset(x: 120 - avatarSize.value,
                                                  y: -120 + avatarSize.value)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                    }
                    .scaledFrame(size: 120, alignment: .bottomLeading)
            }
            .scaledFrame(size: 120)
            
        } else {
            LoadableAvatarImage(url: mainAvatarInfo.avatarURL,
                                name: mainAvatarInfo.name,
                                contentID: mainAvatarInfo.id,
                                avatarSize: avatarSize,
                                imageProvider: imageProvider)
        }
    }
    
    var body: some View {
        VStack(spacing: 8.0) {
            Button {
                onAvatarTap?()
            } label: {
                avatar
            }
            .buttonStyle(.borderless) // Add a button style to stop the whole row being tappable.
            
            Spacer()
                .frame(height: 9)
            
            Text(mainAvatarInfo.name ?? mainAvatarInfo.id)
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
                                         avatarURL: URL.picturesDirectory,
                                         canonicalAlias: "#test:matrix.org",
                                         isEncrypted: true,
                                         isPublic: true),
                             avatarSize: .room(on: .details),
                             imageProvider: MockMediaProvider()) {
                HStack(spacing: 32) {
                    ShareLink(item: "test") {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: "Test"))
                }
                .padding(.top, 32)
            }
        }
        .previewDisplayName("Room")
        
        Form {
            AvatarHeaderView(accountOwner: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockMe), dmRecipient: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockAlice),
                             imageProvider: MockMediaProvider()) {
                HStack(spacing: 32) {
                    ShareLink(item: "test") {
                        Image(systemName: "square.and.arrow.up")
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
                             imageProvider: MockMediaProvider()) { Text("") }
            
            AvatarHeaderView(member: RoomMemberDetails(withProxy: RoomMemberProxyMock.mockBanned[3]),
                             avatarSize: .room(on: .details),
                             imageProvider: MockMediaProvider()) { Text("") }
        }
        .padding()
        .background(Color.compound.bgSubtleSecondaryLevel0)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Members")
    }
}
