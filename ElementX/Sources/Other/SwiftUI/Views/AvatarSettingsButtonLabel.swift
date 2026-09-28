//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AvatarSettingsButtonLabel: View {
    @Environment(\.isInSidebar) private var isInSidebar
    
    let userProfile: UserProfile
    let mediaProvider: MediaProviderProtocol?
    
    var isCompact: Bool {
        guard #available(iOS 26, *) else { return true }
        return isInSidebar // iPad doesn't use glass buttons in the sidebar.
    }
    
    var body: some View {
        LoadableAvatarImage(url: userProfile.avatarURL,
                            name: userProfile.displayName,
                            contentID: userProfile.id,
                            avatarSize: .user(on: isCompact ? .chatsCompact : .chats),
                            mediaProvider: mediaProvider)
            .modifier(StatusEmojiModifier(statusEmoji: userProfile.status.displayed?.emoji,
                                          isCompact: isCompact))
            .geometryGroup()
            .accessibilityHidden(true) // Decorative, the enclosing button provides the description.
    }
}

private struct StatusEmojiModifier: ViewModifier {
    let statusEmoji: Character?
    let isCompact: Bool
    
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
                .font(emojiFont)
                .padding(.vertical, 1) // Match Figma's line height.
                .alignmentGuide(.trailing) { $0.width - trailingOffset }
                .alignmentGuide(.bottom) { $0.height + bottomOffset }
        }
    }
    
    // Values scaled by 0.8 in the compact layout for a button size of 32pt instead of 40pt.
    
    var emojiFont: Font {
        isCompact ? .compound.bodyXS : .compound.bodyMD
    }
    
    nonisolated var trailingOffset: CGFloat {
        isCompact ? 6.5 : 8
    }
    
    nonisolated var bottomOffset: CGFloat {
        isCompact ? 1.5 : 2
    }
}

struct AvatarSettingsButtonLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 24) {
            states
                .environment(\.isInSidebar, false)
            
            states
                .environment(\.isInSidebar, true)
        }
        .padding(16)
        .previewLayout(.sizeThatFits)
    }
    
    static var states: some View {
        HStack(spacing: 16) {
            AvatarSettingsButtonLabel(userProfile: .mockAlice,
                                      mediaProvider: MediaProviderMock(.init()))
            
            AvatarSettingsButtonLabel(userProfile: .init(userID: "",
                                                         avatarURL: .mockMXCUserAvatar,
                                                         status: .mock(text: "", emoji: "🌴")),
                                      mediaProvider: MediaProviderMock(.init()))
        }
    }
}
