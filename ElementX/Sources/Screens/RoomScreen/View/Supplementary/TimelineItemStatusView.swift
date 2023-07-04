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

struct TimelineItemStatusView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    @Environment(\.timelineStyle) private var style
    @Environment(\.readReceiptsEnabled) private var readReceiptsEnabled
    @EnvironmentObject private var context: RoomScreenViewModel.Context

    private var isLastOutgoingMessage: Bool {
        context.viewState.itemIDs.last == timelineItem.id &&
            timelineItem.isOutgoing
    }

    var body: some View {
        if !timelineItem.properties.orderedReadReceipts.isEmpty, readReceiptsEnabled {
            readReceipts
        } else {
            deliveryStatus
        }
    }

    @ViewBuilder
    var deliveryStatus: some View {
        switch timelineItem.properties.deliveryStatus {
        case .sending:
            TimelineDeliveryStatusView(deliveryStatus: .sending)
        case .sent, .none:
            if isLastOutgoingMessage {
                // We only display the sent icon for the latest outgoing message
                TimelineDeliveryStatusView(deliveryStatus: .sent)
            }
        case .sendingFailed:
            // The bubbles handle the failure internally
            if style == .plain {
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .foregroundColor(.compound.iconCriticalPrimary)
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        context.sendFailedConfirmationDialogInfo = .init(transactionID: timelineItem.properties.transactionID)
                    }
            }
        }
    }

    var readReceipts: some View {
        TimelineReadReceiptsView(timelineItem: timelineItem)
            .environmentObject(context)
    }
}
