//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension AggregatedReaction {
    private static func mockIds(_ count: Int) -> [String] {
        Array(1...count).map {
            "@user\($0):matrix.org"
        }
    }
    
    private static func mockReaction(key: String, senderIDs: [String]) -> AggregatedReaction {
        let senders = senderIDs
            .map { id in
                ReactionSender(id: id, timestamp: Date(timeIntervalSinceReferenceDate: 0))
            }
        return AggregatedReaction(accountOwnerID: alice, key: key, senders: senders)
    }
    
    private static var alice: String {
        RoomMemberProxyMock.mockAlice.userID
    }

    static var mockReactions: [AggregatedReaction] {
        [
            mockReaction(key: "😅", senderIDs: [alice]),
            mockReaction(key: "🤷‍♂️", senderIDs: mockIds(1)),
            mockReaction(key: "🎨", senderIDs: [alice] + mockIds(5)),
            mockReaction(key: "🎉", senderIDs: mockIds(8)),
            mockReaction(key: "🤯", senderIDs: [alice] + mockIds(14)),
            mockReaction(key: "🫣", senderIDs: mockIds(1)),
            mockReaction(key: "🚀", senderIDs: [alice] + mockIds(3)),
            mockReaction(key: "😇", senderIDs: mockIds(2)),
            mockReaction(key: "🤭", senderIDs: [alice] + mockIds(8)),
            mockReaction(key: "🫤", senderIDs: mockIds(10)),
            mockReaction(key: "🐶", senderIDs: mockIds(1)),
            mockReaction(key: "🐱", senderIDs: mockIds(1)),
            mockReaction(key: "🐭", senderIDs: mockIds(1)),
            mockReaction(key: "🐹", senderIDs: mockIds(1)),
            mockReaction(key: "🐰", senderIDs: mockIds(1)),
            mockReaction(key: "🦊", senderIDs: mockIds(1)),
            mockReaction(key: "🐻", senderIDs: mockIds(1)),
            mockReaction(key: "🐼", senderIDs: mockIds(1))
        ]
    }
    
    static var mockReactionWithLongText: AggregatedReaction {
        mockReaction(key: "Matrix defines a set of open APIs for decentralised communication.", senderIDs: [alice])
    }
    
    static var mockReactionWithLongTextRTL: AggregatedReaction {
        mockReaction(key: "تحدد المصفوفة مجموعة من واجهات برمجة التطبيقات المفتوحة للتواصل اللامركزي.", senderIDs: [alice])
    }
}
