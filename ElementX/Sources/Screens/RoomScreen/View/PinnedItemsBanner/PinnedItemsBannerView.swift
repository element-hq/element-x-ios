//
// Copyright 2024 New Vector Ltd
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

import Compound
import SwiftUI

struct PinnedItemsBannerView: View {
    let state: PinnedEventsBannerState
    
    let onMainButtonTap: () -> Void
    let onViewAllButtonTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            mainButton
            viewAllButton
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .background(Color.compound.bgCanvasDefault)
        .drawingGroup()
        .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.1), radius: 12, x: 0, y: 4)
    }
    
    private var mainButton: some View {
        Button { onMainButtonTap() } label: {
            HStack(spacing: 0) {
                HStack(spacing: 10) {
                    PinnedItemsIndicatorView(pinIndex: state.selectedPinnedIndex, pinsCount: state.count)
                        .accessibilityHidden(true)
                    CompoundIcon(\.pinSolid, size: .small, relativeTo: .compound.bodyMD)
                        .foregroundColor(Color.compound.iconSecondaryAlpha)
                        .accessibilityHidden(true)
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .disabled(state.isLoading)
        .accessibilityElement(children: .contain)
    }
    
    @ViewBuilder
    private var viewAllButton: some View {
        switch state {
        case .loaded:
            Button { onViewAllButtonTap() } label: {
                Text(L10n.screenRoomPinnedBannerViewAllButtonTitle)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(Color.compound.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
            }
        case .loading:
            ProgressView()
                .padding(.horizontal, 16)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.bannerIndicatorDescription)
                .font(.compound.bodySM)
                .foregroundColor(.compound.textActionAccent)
                .lineLimit(1)
            Text(state.displayedMessage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
    }
}

struct PinnedItemsBannerView_Previews: PreviewProvider, TestablePreview {
    static var attributedContent: AttributedString {
        var boldPart = AttributedString("Image:")
        boldPart.bold()
        var finalString = boldPart + " content.png"
        // This should be ignored when presented
        finalString.font = .headline
        return finalString
    }
    
    static var previews: some View {
        VStack(spacing: 20) {
            PinnedItemsBannerView(state: .loaded(state: .init(pinnedEventContents: ["1": "Content",
                                                                                    "2": "2",
                                                                                    "3": "3"],
                selectedPinnedEventID: "1")),
                                  onMainButtonTap: { },
                                  onViewAllButtonTap: { })
            PinnedItemsBannerView(state: .loaded(state: .init(pinnedEventContents: ["1": "Very very very very long content here",
                                                                                    "2": "2"],
                selectedPinnedEventID: "1")),
                                  onMainButtonTap: { },
                                  onViewAllButtonTap: { })
            PinnedItemsBannerView(state: .loaded(state: .init(pinnedEventContents: ["1": attributedContent],
                                                              selectedPinnedEventID: "1")),
                                  onMainButtonTap: { },
                                  onViewAllButtonTap: { })
            PinnedItemsBannerView(state: .loading(numbersOfEvents: 5),
                                  onMainButtonTap: { },
                                  onViewAllButtonTap: { })
        }
    }
}
