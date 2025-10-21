//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct JoinedMembersBadgeView: View {
    let heroes: [UserProfileProxy]
    let joinedCount: Int
    
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        if heroes.isEmpty {
            Label(title: title) {
                CompoundIcon(\.userProfile, size: .small, relativeTo: .compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
            }
            .font(.compound.bodyMD)
            .foregroundStyle(.compound.textSecondary)
            .labelStyle(.custom(spacing: 4))
            .padding(.trailing, 8)
            .background(.compound.bgSubtleSecondary, in: Capsule())
        } else {
            Label(title: title) {
                heroesFacePile
            }
            .font(.compound.bodyMD)
            .foregroundStyle(.compound.textSecondary)
            .labelStyle(.custom(spacing: 6))
        }
    }
    
    func title() -> Text {
        Text("\(joinedCount)")
    }
    
    var heroesFacePile: some View {
        HStack(spacing: -8) {
            ForEach(heroes.prefix(3).reversed()) { hero in
                LoadableAvatarImage(url: hero.avatarURL,
                                    name: hero.displayName,
                                    contentID: hero.userID,
                                    avatarSize: .user(on: .spaceHeader),
                                    mediaProvider: mediaProvider)
                    .mask {
                        Circle()
                            .fill(Color.white)
                            .overlay {
                                if hero != heroes.first {
                                    Circle()
                                        .inset(by: -2)
                                        .fill(Color.black)
                                        .offset(x: 12)
                                }
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                    }
            }
        }
    }
}

// MARK: - Previews

struct JoinedMembersBadgeView_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static var previews: some View {
        VStack(spacing: 16) {
            JoinedMembersBadgeView(heroes: [],
                                   joinedCount: 123,
                                   mediaProvider: mediaProvider)
            
            JoinedMembersBadgeView(heroes: [.mockAlice, .mockBob, .mockCharlie, .mockDan],
                                   joinedCount: 123,
                                   mediaProvider: mediaProvider)
        }
    }
}
