//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct ReadReceiptsSummaryView: View {
    let orderedReadReceipts: [ReadReceipt]
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.commonSeenBy)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.compound.textPrimary)
                .padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(orderedReadReceipts) { receipt in
                        ReadReceiptCell(readReceipt: receipt,
                                        memberState: context.viewState.members[receipt.userID],
                                        mediaProvider: context.mediaProvider)
                    }
                }
            }
        }
        .padding(.top, 24)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.compound.bgCanvasDefault)
        .presentationDragIndicator(.visible)
    }
}

struct ReadReceiptsSummaryView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie,
            .mockDan
        ]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "Room", members: members))
        let mock = TimelineViewModel(roomProxy: roomProxyMock,
                                     timelineController: MockRoomTimelineController(),
                                     mediaProvider: MockMediaProvider(),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                     userIndicatorController: UserIndicatorControllerMock(),
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics)
        return mock
    }()
    
    static let orderedReadReceipts: [ReadReceipt] = [
        .init(userID: "@alice:matrix.org", formattedTimestamp: "10:00"),
        .init(userID: "@bob:matrix.org", formattedTimestamp: "9:30"),
        .init(userID: "@charlie:matrix.org", formattedTimestamp: "9:00"),
        .init(userID: "@dan:matrix.org", formattedTimestamp: "8:30"),
        .init(userID: "@loading:matrix.org", formattedTimestamp: "Long time ago")
    ]
    
    static var previews: some View {
        ReadReceiptsSummaryView(orderedReadReceipts: orderedReadReceipts)
            .environmentObject(viewModel.context)
    }
}
