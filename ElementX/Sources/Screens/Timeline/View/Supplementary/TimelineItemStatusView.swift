//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
