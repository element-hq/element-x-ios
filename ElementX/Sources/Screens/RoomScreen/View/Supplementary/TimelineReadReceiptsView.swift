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

struct TimelineReadReceiptsView: View {
    let displayNumber = 3
    let timelineItem: EventBasedTimelineItemProtocol
    @EnvironmentObject private var context: RoomScreenViewModel.Context

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: -4) {
                let receiptsToDisplay = timelineItem.properties.orderedReadReceipts.prefix(displayNumber)
                ForEach(0..<receiptsToDisplay.count, id: \.self) { index in
                    let receipt = receiptsToDisplay[index]
                    LoadableAvatarImage(url: context.viewState.members[receipt.userID]?.avatarURL,
                                        name: context.viewState.members[receipt.userID]?.displayName,
                                        contentID: receipt.userID,
                                        avatarSize: .user(on: .readReceipt),
                                        imageProvider: context.imageProvider)
                        .overlay {
                            RoundedRectangle(cornerRadius: .infinity)
                                .stroke(Color.compound.bgCanvasDefault, lineWidth: 1)
                        }
                        .zIndex(Double(displayNumber - index))
                }
            }
            if timelineItem.properties.orderedReadReceipts.count > displayNumber {
                Text("+\(remaining)")
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textPrimary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var remaining: Int {
        timelineItem.properties.orderedReadReceipts.count - displayNumber
    }
    
    private var accessibilityLabel: String {
        if timelineItem.properties.orderedReadReceipts.count == 1 {
            return L10n.a11yReadReceiptsSingle(getDisplayName(at: 0))
        } else if timelineItem.properties.orderedReadReceipts.count <= displayNumber {
            let limit = timelineItem.properties.orderedReadReceipts.count - 1
            var list = ""
            for index in 0 ..< limit {
                list += "\(getDisplayName(at: index))"
                if index != limit - 1 {
                    list += ", "
                }
            }
            let last = getDisplayName(at: limit)
            return L10n.a11ReadReceiptsMultiple(list, last)
        } else if timelineItem.properties.orderedReadReceipts.count > displayNumber {
            var list = ""
            for index in 0..<displayNumber {
                list += "\(getDisplayName(at: index))"
                if index != displayNumber - 1 {
                    list += ", "
                }
            }
            let x = L10n.tr("Localizable", "a11y_read_receipts_multiple_with_others", list, timelineItem.properties.orderedReadReceipts.count)
            MXLog.info(x)
            return x
        }
        return ""
    }
    
    private func getDisplayName(at index: Int) -> String {
        let userID = timelineItem.properties.orderedReadReceipts[index].userID
        return context.viewState.members[userID]?.displayName ?? userID
    }
}

struct TimelineReadReceiptsView_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberProxyMock] = [
        .mockAlice,
        .mockBob,
        .mockCharlie,
        .mockDan,
        .mockMe
    ]

    static let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Test", members: members)),
                                               timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               mediaPlayerProvider: MediaPlayerProviderMock(),
                                               voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               application: ApplicationMock.default,
                                               appSettings: ServiceLocator.shared.settings,
                                               analyticsService: ServiceLocator.shared.analytics,
                                               notificationCenter: NotificationCenterMock())

    static let singleReceipt = [ReadReceipt(userID: RoomMemberProxyMock.mockAlice.userID, formattedTimestamp: "Now")]
    static let doubleReceipt = [ReadReceipt(userID: RoomMemberProxyMock.mockAlice.userID, formattedTimestamp: "Now"),
                                ReadReceipt(userID: RoomMemberProxyMock.mockBob.userID, formattedTimestamp: "Before")]
    static let tripleReceipt = [ReadReceipt(userID: RoomMemberProxyMock.mockAlice.userID, formattedTimestamp: "Now"),
                                ReadReceipt(userID: RoomMemberProxyMock.mockBob.userID, formattedTimestamp: "Before"),
                                ReadReceipt(userID: RoomMemberProxyMock.mockCharlie.userID, formattedTimestamp: "Way before")]
    static let quadrupleReceipt = [ReadReceipt(userID: RoomMemberProxyMock.mockAlice.userID, formattedTimestamp: "Now"),
                                   ReadReceipt(userID: RoomMemberProxyMock.mockBob.userID, formattedTimestamp: "Before"),
                                   ReadReceipt(userID: RoomMemberProxyMock.mockCharlie.userID, formattedTimestamp: "Way before"),
                                   ReadReceipt(userID: RoomMemberProxyMock.mockDan.userID, formattedTimestamp: "Way, way before")]

    static func mockTimelineItem(with receipts: [ReadReceipt]) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: .random,
                             timestamp: "Now",
                             isOutgoing: true,
                             isEditable: false,
                             canBeRepliedTo: true,
                             isThreaded: false,
                             sender: .init(id: UUID().uuidString), content: .init(body: "Test"),
                             properties: .init(orderedReadReceipts: receipts))
    }

    static var previews: some View {
        VStack(spacing: 8) {
            TimelineReadReceiptsView(timelineItem: mockTimelineItem(with: singleReceipt))
                .environmentObject(viewModel.context)
            TimelineReadReceiptsView(timelineItem: mockTimelineItem(with: doubleReceipt))
                .environmentObject(viewModel.context)
            TimelineReadReceiptsView(timelineItem: mockTimelineItem(with: tripleReceipt))
                .environmentObject(viewModel.context)
            TimelineReadReceiptsView(timelineItem: mockTimelineItem(with: quadrupleReceipt))
                .environmentObject(viewModel.context)
        }
    }
}
