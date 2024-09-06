//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Represents all reactions of the same type for a single event.
struct AggregatedReaction: Hashable, Identifiable {
    /// Length at which we ellipsize a reaction key for display
    /// Reactions can be free text, so we need to limit the length
    /// displayed on screen.
    private static let maxDisplayChars = 16
    
    var id: String {
        key
    }
    
    /// The id of the account owner
    let accountOwnerID: String
    /// The reaction that was sent.
    let key: String
    /// The user ids of those who sent the reactions
    let senders: [ReactionSender]
}

/// Details of who sent the reaction
struct ReactionSender: Hashable, Identifiable {
    /// The id of the user who sent the reaction
    let id: String
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
        senders.contains(where: { $0.id == accountOwnerID })
    }
    
    /// The key to be displayed on screen. See `maxDisplayChars`.
    var displayKey: String {
        key.ellipsize(length: Self.maxDisplayChars)
    }
}
