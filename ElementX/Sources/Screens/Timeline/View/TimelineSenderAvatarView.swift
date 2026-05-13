//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

struct TimelineSenderAvatarView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    let timelineItem: EventBasedTimelineItemProtocol
    
    var body: some View {
        LoadableAvatarImage(url: context.viewState.members[timelineItem.sender.id]?.avatarURL ?? timelineItem.sender.avatarURL,
                            name: timelineItem.sender.displayName,
                            contentID: timelineItem.sender.id,
                            avatarSize: .user(on: .timeline),
                            mediaProvider: context.mediaProvider)
            .overlay {
                Circle().stroke(Color.compound.bgCanvasDefault, lineWidth: 3)
            }
    }
}
