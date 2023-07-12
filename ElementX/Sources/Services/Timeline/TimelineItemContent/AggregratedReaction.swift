//
// Copyright 2022 New Vector Ltd
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

/// Represents all reactions of the same type for a single event.
struct AggregatedReaction: Hashable {
    /// The id of the account owner
    let accountOwnerID: String
    /// The reaction that was sent.
    let key: String
    /// The user ids of those who sent the reactions
    let senders: [ReactionSender]
}

/// Details of who sent the reaction
struct ReactionSender: Hashable {
    /// The id of the user who sent the reaction
    let senderId: String
    /// The time that the reaction was received on the original homeserver
    let timestamp: Date
}

extension AggregatedReaction {
    /// The number of times this reactions was sent.
    var count: Int {
        senders.count
    }
    
    /// Whether to highlight the reaction, indicating that the current user sent this reaction.
    var isHighlighted: Bool {
        senders.contains(where: { $0.senderId == accountOwnerID })
    }
}
