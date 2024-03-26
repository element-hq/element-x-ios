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
    @Environment(\.isEnabled) private var isEnabled
    
    let pollOption: Poll.Option
    let showVotes: Bool
    let isFinalResult: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemSymbol: pollOption.isSelected ? .checkmarkCircleFill : .circle)
                .font(.compound.bodyLG)
                .foregroundColor(pollOption.isSelected && isEnabled ? .compound.iconPrimary : .compound.iconTertiary)
                .accessibilityAddTraits(pollOption.isSelected ? .isSelected : [])

            VStack(spacing: 10) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(pollOption.text)
                        .font(isFinalWinningOption ? .compound.bodyLGSemibold : .compound.bodyLG)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if showVotes {
                        if isFinalWinningOption {
                            HStack(spacing: 4) {
                                Asset.Images.pollWinner.swiftUIImage
                                
                                Text(L10n.commonPollVotesCount(pollOption.votes))
                                    .font(.compound.bodySMSemibold)
                                    .foregroundColor(.compound.textPrimary)
                            }
                        } else {
                            Text(L10n.commonPollVotesCount(pollOption.votes))
                                .font(.compound.bodySM)
                                .foregroundColor(.compound.textSecondary)
                        }
                    }
                }

                PollProgressView(progress: progress)
            }
        }
    }

    // MARK: - Private

    private var progress: Double {
        switch (showVotes, pollOption.allVotes, pollOption.isSelected) {
        case (true, let allVotes, _) where allVotes > 0:
            return Double(pollOption.votes) / Double(allVotes)
        case (false, _, true):
            return 1
        default:
            return 0
        }
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
                    .foregroundColor(.compound._bgEmptyItemAlpha)

                Capsule()
                    .frame(maxWidth: progress * geometry.size.width)
            }
        }
        .frame(height: 6)
    }
}

struct PollOptionView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
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
