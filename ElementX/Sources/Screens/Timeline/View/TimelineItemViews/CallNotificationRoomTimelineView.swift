//
// Copyright 2024 New Vector Ltd
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

import Compound
import Foundation
import SwiftUI

struct CallNotificationRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    let timelineItem: CallNotificationRoomTimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: timelineItem.sender.avatarURL,
                                name: timelineItem.sender.displayName ?? timelineItem.sender.id,
                                contentID: timelineItem.sender.id,
                                avatarSize: .user(on: .timeline),
                                mediaProvider: context.mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(timelineItem.sender.disambiguatedDisplayName ?? timelineItem.sender.id)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Label(title: { Text(L10n.commonCallStarted) },
                      icon: { CompoundIcon(\.videoCallSolid, size: .medium, relativeTo: .compound.bodyMD) })
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .labelStyle(.custom(spacing: 4))
            }
            
            Spacer()
            
            Text(timelineItem.timestamp)
                .font(.compound.bodyXS)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.compound.borderInteractiveSecondary, lineWidth: 1)
        )
        .padding(16)
    }
}

struct CallNotificationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        CallNotificationRoomTimelineView(timelineItem: .init(id: .random,
                                                             timestamp: "Now",
                                                             isEditable: false,
                                                             canBeRepliedTo: false,
                                                             sender: .init(id: "Bob")))
    }
}
