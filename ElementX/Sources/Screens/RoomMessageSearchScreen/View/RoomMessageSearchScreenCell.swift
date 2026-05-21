//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomMessageSearchScreenCell: View {
    let result: RoomMessageSearchResult
    let mediaProvider: MediaProviderProtocol?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            LoadableAvatarImage(url: result.sender.avatarURL,
                                name: result.sender.displayName,
                                contentID: result.sender.id,
                                avatarSize: .user(on: .threadList),
                                mediaProvider: mediaProvider)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(result.sender.disambiguatedDisplayName ?? result.sender.id)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(result.timestamp.formattedMinimal())
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }

                if let message = result.message {
                    Text(message)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
