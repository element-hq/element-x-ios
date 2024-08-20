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

import Compound
import SwiftUI

struct TimelineItemStatusView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    let adjustedDeliveryStatus: TimelineItemDeliveryStatus?
    @EnvironmentObject private var context: TimelineViewModel.Context

    private var isLastOutgoingMessage: Bool {
        timelineItem.isOutgoing && context.viewState.timelineViewState.timelineIDs.last == timelineItem.id.timelineID
    }

    var body: some View {
        mainContent
    }

    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.isPinnedEventsTimeline {
            // Do not display any status when is a pinned events timeline
            EmptyView()
        } else if context.viewState.showReadReceipts, !timelineItem.properties.orderedReadReceipts.isEmpty {
            readReceipts
        } else {
            deliveryStatusBadge
        }
    }

    @ViewBuilder
    var deliveryStatusBadge: some View {
        switch adjustedDeliveryStatus {
        case .sending:
            TimelineDeliveryStatusView(deliveryStatus: .sending)
        case .sent, .none:
            if isLastOutgoingMessage {
                // We only display the sent icon for the latest outgoing message
                TimelineDeliveryStatusView(deliveryStatus: .sent)
            }
        case .sendingFailed:
            // Bubbles handle the case internally
            EmptyView()
        }
    }

    var readReceipts: some View {
        TimelineReadReceiptsView(timelineItem: timelineItem)
            .environmentObject(context)
    }
}
