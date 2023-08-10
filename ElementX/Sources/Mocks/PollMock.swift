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

extension Poll {
    static func mock(question: String,
                     pollKind: Poll.Kind = .disclosed,
                     options: [Poll.Option],
                     votes: [String: [String]] = [:],
                     ended: Bool = false) -> Self {
        .init(question: question,
              kind: pollKind,
              maxSelections: 1,
              options: options,
              votes: votes,
              endDate: ended ? Date() : nil)
    }

    static var disclosed: Self {
        mock(question: "What country do you like most?",
             pollKind: .disclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)])
    }

    static var undisclosed: Self {
        mock(question: "What country do you like most?",
             pollKind: .undisclosed,
             options: [.mock(text: "Italy 🇮🇹", votes: 5, allVotes: 10, isWinning: true),
                       .mock(text: "China 🇨🇳", votes: 3, allVotes: 10, isSelected: true),
                       .mock(text: "USA 🇺🇸", votes: 2, allVotes: 10)])
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
    static func mock(poll: Poll) -> Self {
        .init(id: .random,
              poll: poll,
              body: "poll",
              timestamp: "Now",
              isOutgoing: true,
              isEditable: false,
              sender: .init(id: "userID"),
              properties: .init())
    }
}
