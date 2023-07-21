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

import SwiftUI

struct PollRoomTimelineView: View {
    let timelineItem: PollRoomTimelineItem
    @Environment(\.timelineStyle) var timelineStyle

    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Text("Poll: \(poll.question)")
            ForEach(poll.answer, id: \.id) { answer in
                Text(answer.text)
                if let votes = poll.votes[answer.id] {
                    ForEach(votes, id: \.self) { voter in
                        Text("- \(voter)")
                            .padding(.leading, 10)
                    }
                }
            }
            Text("Ended: \(poll.endTime.map(String.init) ?? "Never")")
        }
    }

    // MARK: - Private

    private var poll: Poll {
        timelineItem.poll
    }
}

struct PollRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        PollRoomTimelineView(timelineItem: .init(id: .random,
                                                 poll: .mock,
                                                 body: "Foo",
                                                 timestamp: "Now",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "Bob")))
    }
}

private extension Poll {
    static let mock: Self = .init(question: "Do you like polls?",
                                  pollKind: .disclosed,
                                  maxSelections: 1,
                                  answer: [.init(id: "1", text: "Yes"), .init(id: "2", text: "No")],
                                  votes: [:],
                                  endTime: nil)
}
