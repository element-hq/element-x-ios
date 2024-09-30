//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Poll {
    static func mock(question: String,
                     pollKind: Poll.Kind = .disclosed,
                     options: [Poll.Option],
                     votes: [String: [String]] = [:],
                     ended: Bool = false,
                     createdByAccountOwner: Bool = false) -> Self {
        .init(question: question,
              kind: pollKind,
              maxSelections: 1,
              options: options,
              votes: votes,
              endDate: ended ? Date() : nil,
              createdByAccountOwner: createdByAccountOwner)
    }

    static func disclosed(createdByAccountOwner: Bool = false) -> Self {
        mock(question: "What country do you like most?",
             pollKind: .disclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)],
             createdByAccountOwner: createdByAccountOwner)
    }

    static func undisclosed(createdByAccountOwner: Bool = false) -> Self {
        mock(question: "What country do you like most?",
             pollKind: .undisclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10, isSelected: true),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)],
             createdByAccountOwner: createdByAccountOwner)
    }

    static var endedDisclosed: Self {
        mock(question: "What country do you like most?",
             pollKind: .disclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10, isSelected: true),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)],
             ended: true)
    }

    static var endedUndisclosed: Self {
        mock(question: "What country do you like most?",
             pollKind: .undisclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10, isSelected: true),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)],
             ended: true)
    }
    
    static var emptyDisclosed: Self {
        mock(question: "What country do you like most?",
             pollKind: .disclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 0, allVotes: 0),
                       .mock(text: "China 🇨🇳", votes: 0, allVotes: 0),
                       .mock(text: "USA 🇺🇸", votes: 0, allVotes: 0)],
             createdByAccountOwner: true)
    }
}

extension Poll.Option {
    static func mock(text: String, votes: Int = 0, allVotes: Int = 0, isSelected: Bool = false, isWinning: Bool = false) -> Self {
        .init(id: UUID().uuidString,
              text: text,
              votes: votes,
              allVotes: allVotes,
              isSelected: isSelected,
              isWinning: isWinning)
    }
}

extension PollRoomTimelineItem {
    static func mock(poll: Poll, isOutgoing: Bool = true, isEditable: Bool = false) -> Self {
        .init(id: .init(timelineID: UUID().uuidString, eventID: UUID().uuidString),
              poll: poll,
              body: "poll",
              timestamp: "Now",
              isOutgoing: isOutgoing,
              isEditable: isEditable,
              canBeRepliedTo: true,
              sender: .init(id: "userID"),
              properties: .init())
    }
}
