//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
