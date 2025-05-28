//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct StateRoomTimelineView: View {
    let timelineItem: StateRoomTimelineItem
    let roomMembers: [String: RoomMemberState]?
    
    var body: some View {
        Text(buildStateDisplayText(timelineItem.body))
            .font(.zero.bodySM)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
    }
    
    private func buildStateDisplayText(_ text: String) -> String {
        var stateMessage = text
        let matches = MatrixEntityRegex.userIdentifierRegex.matches(in: text)
        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: text) else {
                break
            }
            let matchedString = String(text[matchRange])
            let userDisplayText = roomMembers?[matchedString]?.displayName ?? matchedString
            stateMessage.replaceSubrange(matchRange, with: userDisplayText)
        }
        return stateMessage
    }
}

struct StateRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        body
    }
    
    static var body: some View {
        StateRoomTimelineView(timelineItem: item, roomMembers: [:])
    }
    
    static let item = StateRoomTimelineItem(id: .randomVirtual,
                                            body: "Alice joined",
                                            timestamp: .mock,
                                            isOutgoing: false,
                                            isEditable: false,
                                            canBeRepliedTo: true,
                                            sender: .init(id: ""))
}
