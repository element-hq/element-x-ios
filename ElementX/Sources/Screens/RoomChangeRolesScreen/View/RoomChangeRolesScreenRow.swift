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

import Compound
import MatrixRustSDK
import SwiftUI

struct RoomChangeRolesScreenRow: View {
    let member: RoomMemberDetails
    let imageProvider: ImageProviderProtocol?
    
    let kind: ListRow<LoadableAvatarImage, EmptyView, EmptyView, Bool>.Kind<EmptyView, Bool>
    
    var body: some View {
        ListRow(label: .avatar(title: member.name ?? member.id,
                               description: member.name == nil ? nil : member.id,
                               icon: avatar),
                kind: kind)
    }
    
    var avatar: LoadableAvatarImage {
        LoadableAvatarImage(url: member.avatarURL,
                            name: member.name,
                            contentID: member.id,
                            avatarSize: .user(on: .startChat),
                            imageProvider: imageProvider)
    }
}

struct RoomChangeRolesScreenRow_Previews: PreviewProvider, TestablePreview {
    static let action: () -> Void = { }
    
    static var previews: some View {
        Form {
            RoomChangeRolesScreenRow(member: .init(withProxy: RoomMemberProxyMock.mockAlice),
                                     imageProvider: MockMediaProvider(),
                                     kind: .multiSelection(isSelected: true, action: action))
            
            RoomChangeRolesScreenRow(member: .init(withProxy: RoomMemberProxyMock.mockBob),
                                     imageProvider: MockMediaProvider(),
                                     kind: .multiSelection(isSelected: false, action: action))
            
            RoomChangeRolesScreenRow(member: .init(withProxy: RoomMemberProxyMock.mockCharlie),
                                     imageProvider: MockMediaProvider(),
                                     kind: .multiSelection(isSelected: true, action: action))
                .disabled(true)
            
            RoomChangeRolesScreenRow(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@someone:matrix.org", membership: .join))),
                                     imageProvider: MockMediaProvider(),
                                     kind: .multiSelection(isSelected: false, action: action))
                .disabled(true)
            
            RoomChangeRolesScreenRow(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@someone:matrix.org", membership: .join))),
                                     imageProvider: MockMediaProvider(),
                                     kind: .multiSelection(isSelected: false, action: action))
        }
        .compoundList()
    }
}
