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

struct TimelineStatusView: View {
    let timelineItem: EventBasedTimelineItemProtocol
    @Environment(\.timelineStyle) private var style
    @EnvironmentObject private var context: RoomScreenViewModel.Context

    @State private var shouldShowDeliveryStatus = true

    private var isLastOutgoingMessage: Bool {
        context.viewState.items.last(where: { !$0.isUnsent })?.id == timelineItem.id &&
            timelineItem.isOutgoing
    }

    private var isLast: Bool {
        context.viewState.items.last?.id == timelineItem.id
    }

    var body: some View {
        if !timelineItem.properties.orderedReadReceipts.isEmpty,
           ServiceLocator.shared.settings.readReceiptsEnabled {
            readReceipts
        } else if shouldShowDeliveryStatus {
            deliveryStatus
                .onChange(of: timelineItem.properties.deliveryStatus) { newValue in
                    if newValue == .sent, !isLast {
                        Task {
                            try? await Task.sleep(for: .milliseconds(1500))
                            withAnimation {
                                shouldShowDeliveryStatus = false
                            }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    var deliveryStatus: some View {
        switch timelineItem.properties.deliveryStatus {
        case .sending:
            TimelineDeliveryStatusView(deliveryStatus: .sending)
        case .sent:
            TimelineDeliveryStatusView(deliveryStatus: .sent)
        case .none:
            if isLastOutgoingMessage {
                // We always display the sent icon for the latest echoed outgoing message
                TimelineDeliveryStatusView(deliveryStatus: .sent)
            }
        case .sendingFailed:
            if style == .plain {
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .foregroundColor(.element.alert)
                    .frame(width: 16, height: 16)
            }
            // The bubbles handle the failure internally
        }
    }

    var readReceipts: some View {
        TimelineReadReceiptsView(timelineItem: timelineItem)
            .environmentObject(context)
    }
}
