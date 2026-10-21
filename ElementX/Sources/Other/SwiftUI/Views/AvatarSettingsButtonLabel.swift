//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AvatarSettingsButton: View {
    @Environment(\.isInSidebar) private var isInSidebar
    
    let userProfile: UserProfile
    let mediaProvider: MediaProviderProtocol?
    let action: () -> Void
    
    var isCompact: Bool {
        guard #available(iOS 26, *) else { return true }
        return isInSidebar // iPad doesn't use glass buttons in the sidebar.
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: action) {
                LoadableAvatarImage(url: userProfile.avatarURL,
                                    name: userProfile.displayName,
                                    contentID: userProfile.id,
                                    avatarSize: .user(on: isCompact ? .chatsCompact : .chats),
                                    mediaProvider: mediaProvider)
            }
            .accessibilityLabel(L10n.commonSettings)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
            
            if let statusEmoji = userProfile.status.displayed?.emoji {
                Text(String(statusEmoji))
                    .font(isCompact ? .compound.bodyXSSemibold : .compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .accessibilityLabel(L10n.a11yStatus)
                    .accessibilityValue(String(statusEmoji))
            }
        }
        .geometryGroup()
    }
}

struct AvatarSettingsButton_Previews: PreviewProvider, TestablePreview {
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
            AvatarSettingsButton(userProfile: .mockAlice,
                                 mediaProvider: MediaProviderMock(.init())) { }
            
            AvatarSettingsButton(userProfile: .init(userID: "",
                                                    avatarURL: .mockMXCUserAvatar,
                                                    status: .mock(text: "", emoji: "🌴")),
                                 mediaProvider: MediaProviderMock(.init())) { }
        }
    }
}
