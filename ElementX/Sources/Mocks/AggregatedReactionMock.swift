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
    
    private static var alice: String {
        RoomMemberProxyMock.mockAlice.userID
    }
    
    static var mockThumbsUpHighlighted: AggregatedReaction {
        AggregatedReaction(accountOwnerID: alice, key: "👍", senders: [alice] + mockIds(4))
    }
    
    static var mockClap: AggregatedReaction {
        AggregatedReaction(accountOwnerID: alice, key: "👏", senders: mockIds(1))
    }
    
    static var mockParty: AggregatedReaction {
        AggregatedReaction(accountOwnerID: alice, key: "🎉", senders: mockIds(20))
    }

    static var mockReactions: [AggregatedReaction] {
        [
            AggregatedReaction(accountOwnerID: alice, key: "😅", senders: [alice]),
            AggregatedReaction(accountOwnerID: alice, key: "🤷‍♂️", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🎨", senders: [alice] + mockIds(5)),
            AggregatedReaction(accountOwnerID: alice, key: "🎉", senders: mockIds(8)),
            AggregatedReaction(accountOwnerID: alice, key: "🤯", senders: [alice] + mockIds(14)),
            AggregatedReaction(accountOwnerID: alice, key: "🫣", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🚀", senders: [alice] + mockIds(3)),
            AggregatedReaction(accountOwnerID: alice, key: "😇", senders: mockIds(2)),
            AggregatedReaction(accountOwnerID: alice, key: "🤭", senders: [alice] + mockIds(8)),
            AggregatedReaction(accountOwnerID: alice, key: "🫤", senders: mockIds(10)),
            AggregatedReaction(accountOwnerID: alice, key: "🐶", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐱", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐭", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐹", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐰", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🦊", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐻", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐼", senders: mockIds(1))
        ]
    }
    
    static var mockReactions2: [AggregatedReaction] {
        [
            AggregatedReaction(accountOwnerID: alice, key: "😅", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🤷‍♂️", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🎨", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🎉", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🤯", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🫣", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🚀", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "😇", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🤭", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🫤", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐶", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐱", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐭", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐹", senders: [alice] + mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐰", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🦊", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐻", senders: mockIds(1)),
            AggregatedReaction(accountOwnerID: alice, key: "🐼", senders: mockIds(1))
        ]
    }
}
