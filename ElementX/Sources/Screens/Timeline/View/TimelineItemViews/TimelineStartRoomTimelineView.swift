//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineStartRoomTimelineView: View {
    let timelineItem: TimelineStartRoomTimelineItem
    @Environment(\.timelineContext) private var context
    
    var body: some View {
        VStack(spacing: 14) {
            if context?.viewState.hasPredecessor == true {
                upgradeDialogue
            }
            // We don't display the title for tombstoned DMs
            if context?.viewState.isDirectOneToOneRoom != true {
                Text(title)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .padding(.bottom, 24)
                    .padding(.top, context?.viewState.hasPredecessor == true ? 0 : 24)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var upgradeDialogue: some View {
        VStack(spacing: 16) {
            Text(L10n.screenRoomTimelineUpgradedRoomMessage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
            Button {
                context?.send(viewAction: .displayPredecessorRoom)
            } label: {
                Text(L10n.screenRoomTimelineUpgradedRoomAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .padding(.horizontal, 16)
        .highlight(gradient: .compound.info, borderColor: .compound.borderInfoSubtle)
    }
    
    private var title: String {
        var text = L10n.screenRoomTimelineBeginningOfRoomNoName
        if let name = timelineItem.name {
            text = L10n.screenRoomTimelineBeginningOfRoom(name)
        }
        return text
    }
}

struct TimelineStartRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock(hasPredecessor: true)
    
    static var previews: some View {
        let item = TimelineStartRoomTimelineItem(name: "Alice and Bob")
        TimelineStartRoomTimelineView(timelineItem: item)
            .previewLayout(.sizeThatFits)
        TimelineStartRoomTimelineView(timelineItem: item)
            .environment(\.timelineContext, viewModel.context)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("with predecessor")
    }
}
