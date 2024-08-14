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

struct RoomChangeRolesScreenSelectedItem: View {
    let member: RoomMemberDetails
    let imageProvider: ImageProviderProtocol?
    let networkMonitor: NetworkMonitorProtocol?
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            avatar
            
            Text(member.name ?? member.id)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Private
    
    var avatar: some View {
        LoadableAvatarImage(url: member.avatarURL,
                            name: member.name,
                            contentID: member.id,
                            avatarSize: .user(on: .inviteUsers),
                            imageProvider: imageProvider,
                            networkMonitor: networkMonitor)
            .overlay(alignment: .topTrailing) {
                if member.role != .administrator {
                    Button(action: dismissAction) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledFrame(size: 20)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.compound.iconOnSolidPrimary, Color.compound.iconPrimary)
                    }
                    .offset(x: 4)
                }
            }
    }
}

struct RoomChangeRolesScreenSelectedItem_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberDetails] = [
        RoomMemberProxyMock.mockAlice,
        RoomMemberProxyMock.mockDan,
        RoomMemberProxyMock.mockVerbose,
        RoomMemberProxyMock(with: .init(userID: "@someone:server.org", membership: .join)),
        RoomMemberProxyMock.mockAdmin
    ]
    .map { .init(withProxy: $0) }
    
    static var previews: some View {
        HStack(spacing: 12) {
            ForEach(members, id: \.id) { member in
                RoomChangeRolesScreenSelectedItem(member: member,
                                                  imageProvider: MockMediaProvider(),
                                                  networkMonitor: NetworkMonitorMock.default,
                                                  dismissAction: { })
                    .frame(width: 72)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
