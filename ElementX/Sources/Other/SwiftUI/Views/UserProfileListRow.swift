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

struct UserProfileListRow: View {
    let user: UserProfileProxy
    let membership: MembershipState?
    let mediaProvider: MediaProviderProtocol?
    
    let kind: ListRow<LoadableAvatarImage, EmptyView, EmptyView, Bool>.Kind<EmptyView, Bool>
    
    var isUnknownProfile: Bool { !user.isVerified && membership == nil }
    
    private var subtitle: String? {
        guard !isUnknownProfile else { return L10n.commonInviteUnknownProfile }
        
        if let membershipText = membership?.localizedDescription {
            return membershipText
        } else if user.displayName != nil {
            return user.userID
        } else {
            return nil
        }
    }
    
    var body: some View {
        ListRow(label: .avatar(title: user.displayName ?? user.userID,
                               description: subtitle,
                               icon: avatar,
                               role: isUnknownProfile ? .error : nil),
                kind: kind)
    }
    
    var avatar: LoadableAvatarImage {
        LoadableAvatarImage(url: user.avatarURL,
                            name: user.displayName,
                            contentID: user.userID,
                            avatarSize: .user(on: .startChat),
                            mediaProvider: mediaProvider)
    }
}

private extension MembershipState {
    var localizedDescription: String? {
        switch self {
        case .join:
            return L10n.screenRoomDetailsAlreadyAMember
        case .invite:
            return L10n.screenRoomDetailsAlreadyInvited
        default:
            return nil
        }
    }
}

struct UserProfileCell_Previews: PreviewProvider, TestablePreview {
    static let action: () -> Void = { }
    
    static var previews: some View {
        Form {
            UserProfileListRow(user: .mockAlice, membership: nil, mediaProvider: MockMediaProvider(),
                               kind: .multiSelection(isSelected: true, action: action))
            
            UserProfileListRow(user: .mockBob, membership: nil, mediaProvider: MockMediaProvider(),
                               kind: .multiSelection(isSelected: false, action: action))
            
            UserProfileListRow(user: .mockCharlie, membership: .join, mediaProvider: MockMediaProvider(),
                               kind: .multiSelection(isSelected: true, action: action))
                .disabled(true)
            
            UserProfileListRow(user: .init(userID: "@someone:matrix.org"), membership: .join, mediaProvider: MockMediaProvider(),
                               kind: .multiSelection(isSelected: false, action: action))
                .disabled(true)
            
            UserProfileListRow(user: .init(userID: "@someone:matrix.org"), membership: nil, mediaProvider: MockMediaProvider(),
                               kind: .multiSelection(isSelected: false, action: action))
        }
        .compoundList()
    }
}
