//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

// MARK: - TimelineStyler

struct TimelineStyler<Content: View>: View {
    let timelineItem: EventBasedTimelineItemProtocol
    @ViewBuilder let content: () -> Content
    
    @State private var adjustedDeliveryStatus: TimelineItemDeliveryStatus?
    @State private var task: Task<Void, Never>?
    
    init(timelineItem: EventBasedTimelineItemProtocol, @ViewBuilder content: @escaping () -> Content) {
        self.timelineItem = timelineItem
        self.content = content
        _adjustedDeliveryStatus = State(initialValue: timelineItem.properties.deliveryStatus)
    }

    var body: some View {
        mainContent
            .onChange(of: timelineItem.properties.deliveryStatus) { newStatus in
                if case .sendingFailed = newStatus {
                    guard task == nil else {
                        return
                    }
                    task = Task {
                        // Add a short delay so that an immediate failure when retrying
                        // shows as sending for long enough to be visible to the user.
                        try? await Task.sleep(for: .milliseconds(700))
                        if !Task.isCancelled {
                            adjustedDeliveryStatus = newStatus
                        }
                        task = nil
                    }
                } else {
                    task?.cancel()
                    task = nil
                    adjustedDeliveryStatus = newStatus
                }
            }
            .animation(.elementDefault, value: adjustedDeliveryStatus)
    }
    
    @ViewBuilder
    var mainContent: some View {
        TimelineItemBubbledStylerView(timelineItem: timelineItem, adjustedDeliveryStatus: adjustedDeliveryStatus, content: content)
    }
}

struct TimelineItemStyler_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock

    static let base = TextRoomTimelineItem(id: .random,
                                           timestamp: "Now",
                                           isOutgoing: true,
                                           isEditable: false,
                                           canBeRepliedTo: true,
                                           isThreaded: false,
                                           sender: .test,
                                           content: .init(body: "Test"))

    static let sentNonLast: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sent
        return result
    }()

    static let sendingNonLast: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sending
        return result
    }()

    static let sendingLast: TextRoomTimelineItem = {
        let id = viewModel.state.timelineViewState.timelineIDs.last ?? UUID().uuidString
        var result = TextRoomTimelineItem(id: .init(timelineID: id),
                                          timestamp: "Now",
                                          isOutgoing: true,
                                          isEditable: false,
                                          canBeRepliedTo: true,
                                          isThreaded: false,
                                          sender: .test,
                                          content: .init(body: "Test"))
        result.properties.deliveryStatus = .sending
        return result
    }()

    static let failed: TextRoomTimelineItem = {
        var result = base
        result.properties.deliveryStatus = .sendingFailed(.unknown)
        return result
    }()

    static let sentLast: TextRoomTimelineItem = {
        let id = viewModel.state.timelineViewState.timelineIDs.last ?? UUID().uuidString
        let result = TextRoomTimelineItem(id: .init(timelineID: id),
                                          timestamp: "Now",
                                          isOutgoing: true,
                                          isEditable: false,
                                          canBeRepliedTo: true,
                                          isThreaded: false,
                                          sender: .test,
                                          content: .init(body: "Test"))
        return result
    }()

    static let ltrString = TextRoomTimelineItem(id: .random,
                                                timestamp: "Now",
                                                isOutgoing: true,
                                                isEditable: false,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .test, content: .init(body: "house!"))

    static let rtlString = TextRoomTimelineItem(id: .random,
                                                timestamp: "Now",
                                                isOutgoing: true,
                                                isEditable: false,
                                                canBeRepliedTo: true,
                                                isThreaded: false,
                                                sender: .test, content: .init(body: "באמת!"))

    static let ltrStringThatContainsRtl = TextRoomTimelineItem(id: .random,
                                                               timestamp: "Now",
                                                               isOutgoing: true,
                                                               isEditable: false,
                                                               canBeRepliedTo: true,
                                                               isThreaded: false,
                                                               sender: .test,
                                                               content: .init(body: "house! -- באמת‏! -- house!"))

    static let rtlStringThatContainsLtr = TextRoomTimelineItem(id: .random,
                                                               timestamp: "Now",
                                                               isOutgoing: true,
                                                               isEditable: false,
                                                               canBeRepliedTo: true,
                                                               isThreaded: false,
                                                               sender: .test,
                                                               content: .init(body: "באמת‏! -- house! -- באמת!"))

    static let ltrStringThatFinishesInRtl = TextRoomTimelineItem(id: .random,
                                                                 timestamp: "Now",
                                                                 isOutgoing: true,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: true,
                                                                 isThreaded: false,
                                                                 sender: .test,
                                                                 content: .init(body: "house! -- באמת!"))

    static let rtlStringThatFinishesInLtr = TextRoomTimelineItem(id: .random,
                                                                 timestamp: "Now",
                                                                 isOutgoing: true,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: true,
                                                                 isThreaded: false,
                                                                 sender: .test,
                                                                 content: .init(body: "באמת‏! -- house!"))

    static var testView: some View {
        VStack(spacing: 0) {
            TextRoomTimelineView(timelineItem: base)
            TextRoomTimelineView(timelineItem: sentNonLast)
            TextRoomTimelineView(timelineItem: sentLast)
            TextRoomTimelineView(timelineItem: sendingNonLast)
            TextRoomTimelineView(timelineItem: sendingLast)
            TextRoomTimelineView(timelineItem: failed)
        }
    }

    static var languagesTestView: some View {
        VStack(spacing: 0) {
            TextRoomTimelineView(timelineItem: ltrString)
            TextRoomTimelineView(timelineItem: rtlString)
            TextRoomTimelineView(timelineItem: ltrStringThatContainsRtl)
            TextRoomTimelineView(timelineItem: rtlStringThatContainsLtr)
            TextRoomTimelineView(timelineItem: ltrStringThatFinishesInRtl)
            TextRoomTimelineView(timelineItem: rtlStringThatFinishesInLtr)
        }
    }

    static var previews: some View {
        testView
            .environmentObject(viewModel.context)
            .previewDisplayName("Bubbles")
        
        languagesTestView
            .environmentObject(viewModel.context)
            .previewDisplayName("Bubbles LTR with different layout languages")

        languagesTestView
            .environmentObject(viewModel.context)
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Bubbles RTL with different layout languages")
    }
}
