//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct BloomView: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            avatar
                .blur(radius: 64)
                .blendMode(colorScheme == .dark ? .exclusion : .hardLight)
                .opacity(colorScheme == .dark ? 0.50 : 0.20)
            avatar
                .blur(radius: 64)
                .blendMode(.color)
                .opacity(colorScheme == .dark ? 0.20 : 0.80)
        }
    }
    
    private var avatar: some View {
        LoadableAvatarImage(url: context.viewState.userAvatarURL,
                            name: context.viewState.userDisplayName,
                            contentID: context.viewState.userID,
                            avatarSize: .custom(256),
                            mediaProvider: context.mediaProvider)
    }
}
