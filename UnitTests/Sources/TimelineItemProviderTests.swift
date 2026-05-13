//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct TimelineItemProviderTests {
    // MARK: - roomMemberEventPublisher

    @Test
    func roomMemberEventPublisherFiresOnMembershipChange() async throws {
        // Given a TimelineItemProvider with a controllable timeline listener.
        let (provider, listener) = try await makeProviderAndListener()

        // When a membership change event arrives via sync.
        let deferred = deferFulfillment(provider.roomMemberEventPublisher) { _ in true }
        let item = makeTimelineItem(content: .roomMembership(userId: "@bob:matrix.org",
                                                             userDisplayName: "Bob",
                                                             change: .joined,
                                                             reason: nil))
        listener.onUpdate(diff: [.pushBack(value: item)])
        try await deferred.fulfill()
    }

    @Test
    func roomMemberEventPublisherFiresOnProfileChange() async throws {
        // Given a TimelineItemProvider with a controllable timeline listener.
        let (provider, listener) = try await makeProviderAndListener()

        // When a profile change event (e.g. avatar update) arrives via sync.
        let deferred = deferFulfillment(provider.roomMemberEventPublisher) { _ in true }
        let item = makeTimelineItem(content: .profileChange(displayName: "Bob",
                                                            prevDisplayName: "Bob",
                                                            avatarUrl: "mxc://matrix.org/newavatar",
                                                            prevAvatarUrl: "mxc://matrix.org/oldavatar"))
        listener.onUpdate(diff: [.pushBack(value: item)])
        try await deferred.fulfill()
    }

    @Test
    func roomMemberEventPublisherDoesNotFireOnRegularMessage() async throws {
        // Given a TimelineItemProvider with a controllable timeline listener.
        let (provider, listener) = try await makeProviderAndListener()

        // When a regular message event arrives via sync.
        var fired = false
        let cancellable = provider.roomMemberEventPublisher.sink { fired = true }
        defer { cancellable.cancel() }
        
        let messageContent = TimelineItemContent.msgLike(content: .init(kind: .redacted,
                                                                        reactions: [],
                                                                        inReplyTo: nil,
                                                                        threadRoot: nil,
                                                                        threadSummary: nil))
        let item = makeTimelineItem(content: messageContent)
        listener.onUpdate(diff: [.pushBack(value: item)])

        // Then the publisher does not fire.
        try await Task.sleep(for: .milliseconds(100))
        #expect(!fired)
    }

    // MARK: - Helpers

    private func makeProviderAndListener() async throws -> (TimelineItemProvider, TimelineListener) {
        var capturedListener: TimelineListener?
        let timelineMock = TimelineSDKMock()
        timelineMock.addListenerListenerClosure = { listener in
            capturedListener = listener
            return TaskHandleSDKMock()
        }

        let provider = TimelineItemProvider(timeline: timelineMock,
                                            kind: .live,
                                            paginationStatePublisher: Empty().eraseToAnyPublisher())

        // addListener is called in a Task inside init, yield until it's captured.
        while capturedListener == nil {
            await Task.yield()
        }

        return try (provider, #require(capturedListener))
    }

    private func makeTimelineItem(content: TimelineItemContent) -> TimelineItem {
        let sdkItem = TimelineItemSDKMock()
        let eventItem = EventTimelineItem(configuration: .init(content: content))
        sdkItem.asEventReturnValue = eventItem
        sdkItem.uniqueIdReturnValue = .init(id: UUID().uuidString)
        return sdkItem
    }
}
