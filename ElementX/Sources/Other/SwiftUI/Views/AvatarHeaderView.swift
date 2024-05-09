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
    let id: String
    let name: String?
    let subtitle: String?
    let avatarURL: URL?
    
    let avatarSize: AvatarSize
    let imageProvider: ImageProviderProtocol?
    var onAvatarTap: (() -> Void)?
    @ViewBuilder var footer: () -> Footer
    
    init(room: RoomDetails,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        id = room.id
        name = room.name
        subtitle = room.canonicalAlias
        avatarURL = room.avatarURL
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
    }
    
    init(member: RoomMemberDetails,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        id = member.id
        name = member.isBanned ? nil : member.name
        subtitle = member.isBanned ? nil : member.name == nil ? nil : member.id
        avatarURL = member.isBanned ? nil : member.avatarURL
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
    }
    
    init(user: UserProfileProxy,
         avatarSize: AvatarSize,
         imageProvider: ImageProviderProtocol? = nil,
         onAvatarTap: (() -> Void)? = nil,
         @ViewBuilder footer: @escaping () -> Footer) {
        id = user.userID
        name = user.displayName
        subtitle = user.displayName == nil ? nil : user.userID
        avatarURL = user.avatarURL
        
        self.avatarSize = avatarSize
        self.imageProvider = imageProvider
        self.onAvatarTap = onAvatarTap
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 8.0) {
            Button {
                onAvatarTap?()
            } label: {
                LoadableAvatarImage(url: avatarURL,
                                    name: name,
                                    contentID: id,
                                    avatarSize: avatarSize,
                                    imageProvider: imageProvider)
            }
            .buttonStyle(.borderless) // Add a button style to stop the whole row being tappable.

            Text(name ?? id)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingLGBold)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            if let subtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyLG)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
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
                                         canonicalAlias: "#test:matrix.org"),
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
