//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceHeaderView: View {
    let spaceRoomProxy: SpaceRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol?
    
    @State private var isPresentingTopic = false
    
    var body: some View {
        VStack(spacing: 16) {
            RoomAvatarImage(avatar: spaceRoomProxy.avatar,
                            avatarSize: .room(on: .spaceHeader),
                            mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(spaceRoomProxy.computedName)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                spaceDetails
                
                SpaceHeaderMembersView(heroes: spaceRoomProxy.heroes,
                                       joinedCount: spaceRoomProxy.joinedMembersCount,
                                       mediaProvider: mediaProvider)
            }
            
            if let topic = spaceRoomProxy.topic {
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
            if let topic = spaceRoomProxy.topic {
                SpaceHeaderTopicSheetView(topic: topic)
            }
        }
    }
    
    var spaceDetails: some View {
        Label {
            Text(L10n.screenSpaceListDetails(spaceDetailsVisibilityTitle, L10n.commonRooms(spaceRoomProxy.childrenCount)))
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textSecondary)
                .multilineTextAlignment(.center)
        } icon: {
            CompoundIcon(spaceDetailsVisibilityIcon, size: .small, relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconTertiary)
        }
    }
    
    var spaceDetailsVisibilityTitle: String {
        switch spaceRoomProxy.joinRule {
        case .public:
            L10n.commonPublicSpace
        case .restricted(let rules), .knockRestricted(let rules):
            // FIXME: Get this from the rule (falling back to a passed in parent??)
            "<Parent name> space"
        case .invite, .knock, .private, .custom, .none:
            L10n.commonPrivateSpace
        }
    }
    
    var spaceDetailsVisibilityIcon: KeyPath<CompoundIcons, Image> {
        switch spaceRoomProxy.joinRule {
        case .public:
            \.public
        case .restricted, .knockRestricted:
            \.space
        case .invite, .knock, .private, .custom, .none:
            \.lock
        }
    }
}

import MatrixRustSDK

struct SpaceHeaderMembersView: View {
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

struct SpaceHeaderView_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = makeSpaceRooms()
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                SpaceHeaderView(spaceRoomProxy: space, mediaProvider: mediaProvider)
            }
        }
    }
    
    static func makeSpaceRooms() -> [SpaceRoomProxyMock] {
        [
            SpaceRoomProxyMock(.init(id: "!space1:matrix.org",
                                     name: "Company Space",
                                     isSpace: true,
                                     childrenCount: 10,
                                     joinedMembersCount: 50)),
            SpaceRoomProxyMock(.init(id: "!space2:matrix.org",
                                     name: "Community Space",
                                     avatarURL: .mockMXCAvatar,
                                     isSpace: true,
                                     childrenCount: 20,
                                     joinedMembersCount: 78,
                                     topic: "Description of the space goes right here.",
                                     joinRule: .public)),
            SpaceRoomProxyMock(.init(id: "!space3:matrix.org",
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
                                     joinRule: .knockRestricted(rules: [.roomMembership(roomId: "")])))
        ]
    }
}
