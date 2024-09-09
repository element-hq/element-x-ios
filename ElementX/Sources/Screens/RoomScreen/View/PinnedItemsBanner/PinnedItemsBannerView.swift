//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        Button { onViewAllButtonTap() } label: {
            Text(state.isLoading ? "" : L10n.screenRoomPinnedBannerViewAllButtonTitle)
                .font(.compound.bodyMDSemibold)
                .foregroundStyle(Color.compound.textPrimary)
                .opacity(state.isLoading ? 0 : 1)
                // Use overlay instead otherwise the sliding animation would not work
                .overlay(alignment: .trailing) {
                    ProgressView()
                        .opacity(state.isLoading ? 1 : 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
        }
        .disabled(state.isLoading)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Only the display the indicator description for more than 1 pinned item
            if state.count > 1 {
                Text(state.bannerIndicatorDescription)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textActionAccent)
                    .lineLimit(1)
            }
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
