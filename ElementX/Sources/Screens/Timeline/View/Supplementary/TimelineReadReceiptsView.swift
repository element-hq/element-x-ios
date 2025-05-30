//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TimelineReadReceiptsView: View {
    let displayNumber = 3
    let timelineItem: EventBasedTimelineItemProtocol
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    var avatars: [StackedAvatarInfo] {
        timelineItem.properties.orderedReadReceipts.prefix(displayNumber).map { receipt in
            StackedAvatarInfo(url: context.viewState.members[receipt.userID]?.avatarURL,
                              name: context.viewState.members[receipt.userID]?.displayName,
                              contentID: receipt.userID)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            StackedAvatarsView(overlap: 6,
                               lineWidth: 1,
                               avatars: avatars, avatarSize: .user(on: .readReceipt),
                               mediaProvider: context.mediaProvider)
                .padding(-1)
            if timelineItem.properties.orderedReadReceipts.count > displayNumber {
                Text("+\(remaining)")
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textPrimary)
            }
        }
        .onTapGesture {
            context.send(viewAction: .displayReadReceipts(itemID: timelineItem.id))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(L10n.a11yReadReceiptsTapToShowAll)
    }
    
    private var remaining: Int {
        timelineItem.properties.orderedReadReceipts.count - displayNumber
    }
    
    private var accessibilityLabel: String {
        if timelineItem.properties.orderedReadReceipts.count == 1 {
            return L10n.a11yReadReceiptsSingle(displayName(at: 0))
        } else if timelineItem.properties.orderedReadReceipts.count <= displayNumber {
            let limit = timelineItem.properties.orderedReadReceipts.count - 1
            let list = (0..<limit).map { displayName(at: $0) }.formatted(.list(type: .and, width: .narrow))
            let last = displayName(at: limit)
            return L10n.a11yReadReceiptsMultiple(list, last)
        } else if timelineItem.properties.orderedReadReceipts.count > displayNumber {
            let list = (0..<displayNumber).map { displayName(at: $0) }.formatted(.list(type: .and, width: .narrow))
            
            // Plurals with string arguments aren't generated correctly so we need to use this
            // https://github.com/SwiftGen/SwiftGen/issues/1089
            return L10n.tr("Localizable", "a11y_read_receipts_multiple_with_others", list, remaining)
        }
        return ""
    }
    
    private func displayName(at index: Int) -> String {
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

    static let viewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Test", members: members)),
                                             timelineController: MockTimelineController(),
                                             mediaProvider: MediaProviderMock(configuration: .init()),
                                             mediaPlayerProvider: MediaPlayerProviderMock(),
                                             voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                             userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                             appMediator: AppMediatorMock.default,
                                             appSettings: ServiceLocator.shared.settings,
                                             analyticsService: ServiceLocator.shared.analytics,
                                             emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                             timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                             clientProxy: ClientProxyMock(.init()))
    
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
        TextRoomTimelineItem(id: .randomEvent,
                             timestamp: .mock,
                             isOutgoing: true,
                             isEditable: false,
                             canBeRepliedTo: true,
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
