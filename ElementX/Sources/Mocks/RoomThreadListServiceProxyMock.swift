//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

struct RoomThreadListProxyMockConfiguration {
    var items: [RoomThreadListItem] = .mocks
}

extension RoomThreadListServiceProxyMock {
    convenience init(_ configuration: RoomThreadListProxyMockConfiguration) {
        self.init()
        
        itemsPublisher = CurrentValueSubject(configuration.items).asCurrentValuePublisher()
        paginationStatePublisher = CurrentValueSubject(.idle(endReached: true)).asCurrentValuePublisher()
        
        paginateReturnValue = .success(())
    }
}

extension Array where Element == RoomThreadListItem {
    static let mocks: [RoomThreadListItem] = [
        .init(id: "1",
              rootMessageDetails: .init(sender: .init(id: "@alice:matrix.org", displayName: "Alice", avatarURL: .mockMXCUserAvatar),
                                        timestamp: .distantPast,
                                        message: .init("Ping")),
              latestMessageDetails: .init(sender: .init(id: "@bob:matrix.org"),
                                          timestamp: .distantFuture,
                                          message: .init("Pong")),
              numberOfReplies: 5),
        .init(id: "2",
              rootMessageDetails: .init(sender: .init(id: "@alice:matrix.org", displayName: "Alice", avatarURL: .mockMXCUserAvatar),
                                        timestamp: .distantPast,
                                        message: .init("Can we schedule a meeting for next week?")),
              latestMessageDetails: .init(sender: .init(id: "@bob:matrix.org"),
                                          timestamp: .distantFuture,
                                          message: .init("Looking forward to our next steps!")),
              numberOfReplies: 10)
    ]
}
