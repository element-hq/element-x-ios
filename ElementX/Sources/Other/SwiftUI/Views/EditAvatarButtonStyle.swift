//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct EditAvatarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(alignment: .bottomTrailing) {
                if isEnabled {
                    EditAvatarBadge()
                        .scaledOffset(x: 8, y: 0, relativeTo: .title)
                }
            }
    }
}

struct EditAvatarBadge: View {
    var body: some View {
        CompoundIcon(\.edit, size: .small, relativeTo: .body)
            .foregroundStyle(.compound.iconPrimary)
            .scaledPadding(5, relativeTo: .title)
            .background {
                Circle()
                    .fill(Color.compound.bgCanvasDefault)
                    .overlay {
                        Circle()
                            .inset(by: -0.5)
                            .stroke(.compound.borderInteractiveSecondary, lineWidth: 1)
                    }
            }
            .scaledPadding(4, relativeTo: .title)
            .background(.compound.bgSubtleSecondaryLevel0, in: Circle())
            .scaledPadding(-4)
            .accessibilityHidden(true)
    }
}

struct EditAvatarButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button { } label: {
                LoadableAvatarImage(url: nil,
                                    name: "Test", contentID: "test",
                                    avatarSize: .user(on: .editUserDetails),
                                    mediaProvider: MediaProviderMock(.init()))
            }
            .buttonStyle(EditAvatarButtonStyle())
            
            Button { } label: {
                LoadableAvatarImage(url: nil,
                                    name: "Test", contentID: "test",
                                    avatarSize: .user(on: .editUserDetails),
                                    mediaProvider: MediaProviderMock(.init()))
            }
            .buttonStyle(EditAvatarButtonStyle())
            .disabled(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.compound.bgSubtleSecondaryLevel0)
    }
}
