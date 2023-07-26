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

struct PollOptionView: View {
    let pollOption: Poll.Option

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            FormRowAccessory(kind: .multipleSelection(isSelected: pollOption.isSelected))

            VStack(spacing: 10) {
                HStack(alignment: .lastTextBaseline) {
                    Text(pollOption.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    #warning("AG: localize")
                    Text("\(pollOption.votes) votes")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }

                progressView
            }
        }
    }

    // MARK: - Private

    private var progressView: some View {
        ProgressView(value: Double(pollOption.votes) / Double(pollOption.allVotes))
            .progressViewStyle(LinearProgressViewStyle(tint: .compound.textPrimary))
    }
}

struct PollOptionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                PollOptionView(pollOption: .init(id: "1",
                                                 text: "Italian 🇮🇹",
                                                 votes: 1,
                                                 allVotes: 10,
                                                 isSelected: true))

                PollOptionView(pollOption: .init(id: "2",
                                                 text: "Chinese 🇨🇳",
                                                 votes: 9,
                                                 allVotes: 10,
                                                 isSelected: false))
            }
            .padding()
        }
    }
}
