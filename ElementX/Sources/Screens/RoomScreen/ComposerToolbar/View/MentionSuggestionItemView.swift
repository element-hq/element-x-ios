//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MentionSuggestionItemView: View {
    let mediaProvider: MediaProviderProtocol?
    let item: SuggestionItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            avatar
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Text(item.displayName)
                        .lineLimit(1)
                        .padding(.vertical, 1) // Compensation for Figma line height.
                    
                    if let statusEmoji = item.statusEmoji {
                        Text(String(statusEmoji))
                    }
                }
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                        .padding(.vertical, 1) // Compensation for Figma line height.
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private var avatar: some View {
        switch item.suggestionType {
        case .user(let user):
            LoadableAvatarImage(url: user.avatarURL, name: user.displayName, contentID: user.id, avatarSize: .user(on: .completionSuggestions), mediaProvider: mediaProvider)
        case .allUsers(let avatar):
            RoomAvatarImage(avatar: avatar, avatarSize: .room(on: .completionSuggestions), mediaProvider: mediaProvider)
        case .room(let room):
            RoomAvatarImage(avatar: room.avatar, avatarSize: .room(on: .completionSuggestions), mediaProvider: mediaProvider)
        }
    }
}

struct MentionSuggestionItemView_Previews: PreviewProvider, TestablePreview {
    static let mockMediaProvider = MediaProviderMock(.init())
    
    static var previews: some View {
        MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                  item: .init(suggestionType: .user(.init(id: "test", displayName: "Test", avatarURL: .mockMXCUserAvatar)),
                                              range: .init(),
                                              rawSuggestionText: ""))
            .previewDisplayName("User")
        
        VStack(alignment: .leading, spacing: 8) {
            MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                      item: .init(suggestionType: .user(.init(id: "@john.smith:example.com",
                                                                              displayName: "John Smith",
                                                                              avatarURL: nil,
                                                                              status: .mockHoliday)),
                                                  range: .init(),
                                                  rawSuggestionText: ""))
            
            MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                      item: .init(suggestionType: .user(.init(id: "@alice.liddel:example.com",
                                                                              displayName: "Alice Liddell",
                                                                              avatarURL: nil,
                                                                              status: .mockCall)),
                                                  range: .init(),
                                                  rawSuggestionText: ""))
            
            MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                      item: .init(suggestionType: .user(.init(id: "@long.name:example.com",
                                                                              displayName: "I have a long name that doesn't fit on one line",
                                                                              avatarURL: nil,
                                                                              status: .mock(text: "Travelling", emoji: "🚆"))),
                                                  range: .init(),
                                                  rawSuggestionText: ""))
        }
        .padding(16)
        .previewDisplayName("User with status")
        
        MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                  item: .init(suggestionType: .user(.init(id: "test2", displayName: nil, avatarURL: nil)),
                                              range: .init(),
                                              rawSuggestionText: ""))
            .previewDisplayName("User no display name")
        
        MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                  item: .init(suggestionType: .allUsers(.room(id: "room", name: "Room", avatarURL: .mockMXCAvatar)),
                                              range: .init(),
                                              rawSuggestionText: ""))
            .previewDisplayName("All users")
        
        MentionSuggestionItemView(mediaProvider: mockMediaProvider,
                                  item: .init(suggestionType: .room(.init(id: "room",
                                                                          canonicalAlias: "#room:matrix.org",
                                                                          name: "Room",
                                                                          avatar: .room(id: "room",
                                                                                        name: "Room", avatarURL: .mockMXCAvatar))),
                                              range: .init(),
                                              rawSuggestionText: ""))
            .previewDisplayName("Room")
    }
}
