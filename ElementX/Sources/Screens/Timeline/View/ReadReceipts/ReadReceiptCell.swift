//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct ReadReceiptCell: View {
    let readReceipt: ReadReceipt
    let memberState: RoomMemberState?
    let mediaProvider: MediaProviderProtocol?
    
    private var title: String {
        memberState?.displayName ?? readReceipt.userID
    }
    
    private var subtitle: String {
        guard title != readReceipt.userID else {
            return ""
        }
        return readReceipt.userID
    }
        
    var body: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: memberState?.avatarURL,
                                name: memberState?.displayName,
                                contentID: readReceipt.userID,
                                avatarSize: .user(on: .readReceiptSheet),
                                mediaProvider: mediaProvider)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let formattedTimestamp = readReceipt.formattedTimestamp {
                        Text(formattedTimestamp)
                            .font(.compound.bodyXS)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
                    }
                }
                Text(subtitle)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct ReadReceiptCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ReadReceiptCell(readReceipt: .init(userID: "@test:matrix.org",
                                           formattedTimestamp: "10:00"),
                        memberState: .init(displayName: "Test",
                                           avatarURL: nil),
                        mediaProvider: MockMediaProvider())
            .previewDisplayName("No Image")
        ReadReceiptCell(readReceipt: .init(userID: "@test:matrix.org",
                                           formattedTimestamp: "10:00"),
                        memberState: .init(displayName: "Test",
                                           avatarURL: URL.documentsDirectory),
                        mediaProvider: MockMediaProvider())
            .previewDisplayName("With Image")
        ReadReceiptCell(readReceipt: .init(userID: "@test:matrix.org",
                                           formattedTimestamp: "10:00"),
                        memberState: nil,
                        mediaProvider: MockMediaProvider())
            .previewDisplayName("Loading Member")
    }
}
