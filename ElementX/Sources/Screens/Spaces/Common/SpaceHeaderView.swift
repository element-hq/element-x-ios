//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceHeaderView: View {
    let spaceServiceRoom: SpaceServiceRoom
    let mediaProvider: MediaProviderProtocol?
    
    @State private var isPresentingTopic = false
    
    var body: some View {
        VStack(spacing: 16) {
            RoomAvatarImage(avatar: spaceServiceRoom.avatar,
                            avatarSize: .room(on: .spaceHeader),
                            mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(spaceServiceRoom.name)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let alias = spaceServiceRoom.canonicalAlias {
                    CopyTextButton(content: alias)
                }
                
                spaceDetails
                
                JoinedMembersBadgeView(heroes: spaceServiceRoom.heroes,
                                       joinedCount: spaceServiceRoom.joinedMembersCount,
                                       mediaProvider: mediaProvider)
            }
            
            if let topic = spaceServiceRoom.topic {
                Button { isPresentingTopic = true } label: {
                    Text(topic)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.compound.borderDisabled)
                .frame(height: 1 / UIScreen.main.scale)
        }
        .sheet(isPresented: $isPresentingTopic) {
            if let topic = spaceServiceRoom.topic {
                SpaceHeaderTopicSheetView(topic: topic)
            }
        }
    }
    
    private var spaceDetails: some View {
        Label {
            Text(spaceDetailsVisibilityTitle)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textSecondary)
                .multilineTextAlignment(.center)
        } icon: {
            CompoundIcon(spaceDetailsVisibilityIcon, size: .small, relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconTertiary)
        }
    }
    
    private var spaceDetailsVisibilityTitle: String {
        switch spaceServiceRoom.visibility {
        case .public: L10n.commonPublicSpace
        case .private: L10n.commonPrivateSpace
        case .restricted: L10n.commonSharedSpace
        case .none: L10n.commonPrivateSpace
        }
    }
    
    private var spaceDetailsVisibilityIcon: KeyPath<CompoundIcons, Image> {
        switch spaceServiceRoom.visibility {
        case .public: \.public
        case .private: \.lock
        case .restricted: \.space
        case .none: \.lock
        }
    }
}

// MARK: - Previews

struct SpaceHeaderView_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = makeSpaceRooms()
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                SpaceHeaderView(spaceServiceRoom: space, mediaProvider: mediaProvider)
            }
        }
    }
    
    static func makeSpaceRooms() -> [SpaceServiceRoom] {
        [
            SpaceServiceRoom.mock(id: "!space1:matrix.org",
                                  name: "Company Space",
                                  isSpace: true,
                                  childrenCount: 10,
                                  joinedMembersCount: 50),
            SpaceServiceRoom.mock(id: "!space2:matrix.org",
                                  name: "Community Space",
                                  avatarURL: .mockMXCAvatar,
                                  isSpace: true,
                                  childrenCount: 20,
                                  joinedMembersCount: 78,
                                  topic: "Description of the space goes right here.",
                                  canonicalAlias: "#space:matrix.org",
                                  joinRule: .public),
            SpaceServiceRoom.mock(id: "!space3:matrix.org",
                                  name: "Subspace",
                                  isSpace: true,
                                  childrenCount: 30,
                                  joinedMembersCount: 123,
                                  heroes: [.mockDan, .mockBob, .mockCharlie, .mockVerbose],
                                  topic: ["Description of the space goes right here.",
                                          "Lorem ipsum dolor sit amet consectetur.",
                                          "Leo viverra morbi habitant in.",
                                          "Sem amet enim habitant nibh augue mauris.",
                                          "Interdum mauris ultrices tincidunt proin morbi erat aenean risus nibh.",
                                          "Diam amet sit fermentum vulputate faucibus."].joined(separator: " "),
                                  canonicalAlias: "#subspace:matrix.org",
                                  joinRule: .knockRestricted(rules: [.roomMembership(roomID: "")]))
        ]
    }
}
