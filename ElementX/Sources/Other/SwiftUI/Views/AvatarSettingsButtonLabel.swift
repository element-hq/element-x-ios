//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AvatarSettingsButtonLabel: View {
    let userProfile: UserProfile
    var requiresExtraAccountSetup = false
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        LoadableAvatarImage(url: userProfile.avatarURL,
                            name: userProfile.displayName,
                            contentID: userProfile.id,
                            avatarSize: .user(on: .chats),
                            mediaProvider: mediaProvider)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
            .overlayBadge(10, isBadged: requiresExtraAccountSetup)
            .modifier(StatusEmojiModifier(statusEmoji: userProfile.status.displayed?.emoji))
            .geometryGroup()
    }
}

private struct StatusEmojiModifier: ViewModifier {
    let statusEmoji: Character?
    
    func body(content: Content) -> some View {
        if let emojiText {
            content
                .inverseMask(alignment: .bottomTrailing) {
                    emojiText
                        .hidden()
                        .overlay { Circle().inset(by: -3) }
                }
                .overlay(alignment: .bottomTrailing) {
                    emojiText
                }
        } else {
            content
        }
    }
    
    var emojiText: (some View)? {
        statusEmoji.map {
            Text(String($0))
                // All values (inc font) scaled by 0.8 as our Liquid Glass avatar is 32pt and not 40pt.
                .font(.compound.bodyXS)
                .padding(.vertical, 1) // Match Figma's line height.
                .alignmentGuide(.trailing) { $0.width - 6.5 }
                .alignmentGuide(.bottom) { $0.height + 1.5 }
        }
    }
}

struct AvatarSettingsButtonLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 16) {
            AvatarSettingsButtonLabel(userProfile: .mockAlice,
                                      requiresExtraAccountSetup: false,
                                      mediaProvider: MediaProviderMock(.init()))
            
            AvatarSettingsButtonLabel(userProfile: .mockAlice,
                                      requiresExtraAccountSetup: true,
                                      mediaProvider: MediaProviderMock(.init()))
            
            AvatarSettingsButtonLabel(userProfile: .init(userID: "",
                                                         avatarURL: .mockMXCUserAvatar,
                                                         status: .mock(text: "", emoji: "🌴")),
                                      requiresExtraAccountSetup: false,
                                      mediaProvider: MediaProviderMock(.init()))
            
            AvatarSettingsButtonLabel(userProfile: .init(userID: "",
                                                         avatarURL: .mockMXCUserAvatar,
                                                         status: .mock(text: "", emoji: "🌴")),
                                      requiresExtraAccountSetup: true,
                                      mediaProvider: MediaProviderMock(.init()))
        }
        .padding(16)
        .previewLayout(.sizeThatFits)
    }
}
