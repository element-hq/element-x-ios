//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct TimelineSenderAvatarView: View {
    @Environment(\.timelineContext) private var context

    let timelineItem: EventBasedTimelineItemProtocol
    let onTap: ((URL) -> Void)?
        
    var body: some View {
        LoadableAvatarImage(url: timelineItem.sender.avatarURL,
                            name: timelineItem.sender.displayName,
                            contentID: timelineItem.sender.id,
                            avatarSize: .user(on: .timeline),
                            mediaProvider: context?.mediaProvider,
                            onTap: onTap)
            .overlay {
                Circle().stroke(Color.zero.bgCanvasDefault, lineWidth: 3)
            }
    }
}
