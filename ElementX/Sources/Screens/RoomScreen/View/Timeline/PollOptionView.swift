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
    let showVotes: Bool
    let isFinalResult: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isFinalResult {
                FormRowAccessory(kind: .multipleSelection(isSelected: pollOption.isSelected))
            }

            VStack(spacing: 10) {
                HStack(alignment: .lastTextBaseline) {
                    Text(pollOption.text)
                        .font(isFinalWinningOption ? .compound.bodyLGSemibold : .compound.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if showVotes {
                        Text(L10n.commonPollVotesCount(pollOption.votes))
                            .font(isFinalWinningOption ? .compound.bodySMSemibold : .compound.bodySM)
                            .foregroundColor(isFinalWinningOption ? .compound.textPrimary : .compound.textSecondary)
                    }
                }

                progressView
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var progressView: some View {
        PollProgressView(progress: progress)
    }

    private var progress: Double {
        guard showVotes, pollOption.allVotes > 0 else {
            return 0
        }

        return Double(pollOption.votes) / Double(pollOption.allVotes)
    }

    private var isFinalWinningOption: Bool {
        pollOption.isWinning && isFinalResult
    }
}

private struct PollProgressView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .foregroundColor(.compound.borderDisabled)

                Capsule()
                    .frame(maxWidth: progress * geometry.size.width)
            }
        }
        .frame(height: 6)
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
                                                 isSelected: true,
                                                 isWinning: false),
                               showVotes: false,
                               isFinalResult: false)

                PollOptionView(pollOption: .init(id: "2",
                                                 text: "Chinese 🇨🇳",
                                                 votes: 9,
                                                 allVotes: 10,
                                                 isSelected: false,
                                                 isWinning: true),
                               showVotes: true,
                               isFinalResult: false)

                PollOptionView(pollOption: .init(id: "2",
                                                 text: "Chinese 🇨🇳",
                                                 votes: 9,
                                                 allVotes: 10,
                                                 isSelected: false,
                                                 isWinning: true),
                               showVotes: true,
                               isFinalResult: true)
            }
            .padding()
        }
    }
}
