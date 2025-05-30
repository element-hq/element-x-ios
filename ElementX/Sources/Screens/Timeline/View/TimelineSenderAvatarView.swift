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
        
    var body: some View {
        LoadableAvatarImage(url: timelineItem.sender.avatarURL,
                            name: timelineItem.sender.displayName,
                            contentID: timelineItem.sender.id,
                            avatarSize: .user(on: .timeline),
                            mediaProvider: context?.mediaProvider)
            .overlay {
                Circle().stroke(Color.compound.bgCanvasDefault, lineWidth: 3)
            }
    }
}
