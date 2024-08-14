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
                                        imageProvider: context.dependencies?.imageProvider,
                                        networkMonitor: context.dependencies?.networkMonitor)
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
        let roomProxyMock = RoomProxyMock(.init(name: "Room", members: members))
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
