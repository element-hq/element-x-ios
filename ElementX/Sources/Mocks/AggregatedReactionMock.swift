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
                ReactionSender(senderID: id, timestamp: Date())
            }
        return AggregatedReaction(accountOwnerID: alice, key: key, senders: senders)
    }
    
    private static var alice: String {
        RoomMemberProxyMock.mockAlice.userID
    }
    
    static var mockThumbsUpHighlighted: AggregatedReaction {
        mockReaction(key: "👍", senderIDs: [alice] + mockIds(4))
    }
    
    static var mockClap: AggregatedReaction {
        mockReaction(key: "👏", senderIDs: mockIds(1))
    }
    
    static var mockParty: AggregatedReaction {
        mockReaction(key: "🎉", senderIDs: mockIds(20))
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
}
