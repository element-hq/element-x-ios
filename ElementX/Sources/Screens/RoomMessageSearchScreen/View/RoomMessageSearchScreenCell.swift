//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A room message search result row. Sender-first, since every hit is from the room the user is in.
struct RoomMessageSearchScreenCell: View {
    let result: RoomMessageSearchResult
    let mediaProvider: MediaProviderProtocol?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                LoadableAvatarImage(url: result.sender.avatarURL,
                                    name: result.sender.displayName,
                                    contentID: result.sender.id,
                                    avatarSize: .user(on: .search),
                                    mediaProvider: mediaProvider)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(result.senderName)
                            .font(.compound.bodyLGSemibold)
                            .foregroundStyle(.compound.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(result.timestamp.formattedMinimal())
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    if let preview = result.preview {
                        Text(preview)
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let mediaPreview = result.mediaPreview {
                        SearchScreenMediaPreviewView(preview: mediaPreview, mediaProvider: mediaProvider)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .rowDivider()
    }
}
