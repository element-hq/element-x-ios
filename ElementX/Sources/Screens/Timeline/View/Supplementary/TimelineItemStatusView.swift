//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TimelineItemStatusView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    let adjustedDeliveryStatus: TimelineItemDeliveryStatus?
    @EnvironmentObject private var context: TimelineViewModel.Context
    @State private var isSendReceiptVisible: Bool

    private var isLastOutgoingMessage: Bool {
        timelineItem.isOutgoing && context.viewState.timelineState.uniqueIDs.last == timelineItem.id.uniqueID
    }

    init(timelineItem: EventBasedTimelineItemProtocol, adjustedDeliveryStatus: TimelineItemDeliveryStatus?, context: TimelineViewModel.Context, isSendReceiptVisible: Bool = false) {
        self.timelineItem = timelineItem
        self.adjustedDeliveryStatus = adjustedDeliveryStatus
        // Ugly - we can't call isLastOutgoingMessage here as the real `context` hasn't loaded yet
        // so instead we manually pass in context to init() and duplicate isLastOutgoingMessage here.
        self.isSendReceiptVisible = timelineItem.isOutgoing && context.viewState.timelineState.uniqueIDs.last == timelineItem.id.uniqueID
    }

    var body: some View {
        mainContent
            .onChange(of: context.viewState.timelineState.uniqueIDs.last) { _, _ in
                if isLastOutgoingMessage {
                    isSendReceiptVisible = true
                } else if isSendReceiptVisible {
                    // we were the last msg in the timeline, but not any more
                    // so remove the SR after a short delay to avoid racing with the new msg animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        withAnimation {
                            isSendReceiptVisible = false
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.timelineKind == .pinned {
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
            if isSendReceiptVisible {
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
