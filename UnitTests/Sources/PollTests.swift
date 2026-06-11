//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct PollTests {
    @Test
    func singleSelectionReplacesSelectedAnswer() {
        let poll = Poll.mock(question: "Question?",
                             maxSelections: 1,
                             options: [
                                 .mock(id: "first", text: "First", isSelected: true),
                                 .mock(id: "second", text: "Second")
                             ])
        
        #expect(poll.answerIDsAfterSelecting(optionID: "second") == ["second"])
        #expect(poll.answerIDsAfterSelecting(optionID: "first") == nil)
    }
    
    @Test
    func multipleSelectionAddsAnswerUntilLimit() {
        let poll = Poll.mock(question: "Question?",
                             maxSelections: 2,
                             options: [
                                 .mock(id: "first", text: "First", isSelected: true),
                                 .mock(id: "second", text: "Second"),
                                 .mock(id: "third", text: "Third")
                             ])
        
        #expect(poll.answerIDsAfterSelecting(optionID: "second") == ["first", "second"])
    }
    
    @Test
    func multipleSelectionCanRemoveAnswerWhenMoreThanOneIsSelected() {
        let poll = Poll.mock(question: "Question?",
                             maxSelections: 2,
                             options: [
                                 .mock(id: "first", text: "First", isSelected: true),
                                 .mock(id: "second", text: "Second", isSelected: true),
                                 .mock(id: "third", text: "Third")
                             ])
        
        #expect(poll.answerIDsAfterSelecting(optionID: "first") == ["second"])
    }
    
    @Test
    func multipleSelectionDoesNotAddAnswerOverLimit() {
        let poll = Poll.mock(question: "Question?",
                             maxSelections: 2,
                             options: [
                                 .mock(id: "first", text: "First", isSelected: true),
                                 .mock(id: "second", text: "Second", isSelected: true),
                                 .mock(id: "third", text: "Third")
                             ])
        
        #expect(poll.answerIDsAfterSelecting(optionID: "third") == nil)
    }
}

private extension Poll.Option {
    static func mock(id: String, text: String, isSelected: Bool = false) -> Self {
        .init(id: id,
              text: text,
              votes: 0,
              allVotes: 0,
              isSelected: isSelected,
              isWinning: false)
    }
}
