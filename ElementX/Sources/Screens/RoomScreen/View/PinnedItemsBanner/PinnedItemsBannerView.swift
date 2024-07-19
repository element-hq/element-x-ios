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

import SwiftUI

import Compound

struct PinnedItemsBannerView: View {
    let pinIndex: Int
    let pinsCount: Int
    let pinContent: AttributedString
    
    let onMainButtonTap: () -> Void
    let onViewAllButtonTap: () -> Void
    
    private var bannerIndicatorDescription: AttributedString {
        let index = pinIndex + 1
        let boldPlaceholder = "{bold}"
        var finalString = AttributedString(L10n.Screen.Room.pinnedBannerIndicatorDescription(boldPlaceholder))
        var boldString = AttributedString(L10n.Screen.Room.pinnedBannerIndicator(index, pinsCount))
        boldString.bold()
        finalString.replace(boldPlaceholder, with: boldString)
        return finalString
    }
    
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
        Button(action: onMainButtonTap,
               label: {
                   HStack(spacing: 0) {
                       HStack(spacing: 10) {
                           PinnedItemsIndicatorView(pinIndex: pinIndex, pinsCount: pinsCount)
                               .accessibilityHidden(true)
                           CompoundIcon(\.pinSolid, size: .small, relativeTo: .compound.bodyMD)
                               .foregroundColor(Color.compound.iconSecondaryAlpha)
                               .accessibilityHidden(true)
                           content
                       }
                       Spacer()
                   }
               })
               .accessibilityElement(children: .contain)
    }
    
    private var viewAllButton: some View {
        Button(action: onViewAllButtonTap,
               label: {
                   Text(L10n.Screen.Room.pinnedBannerViewAllButtonTitle)
                       .font(.compound.bodyMDSemibold)
                       .foregroundStyle(Color.compound.textPrimary)
                       .padding(.horizontal, 16)
                       .padding(.vertical, 5)
               })
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(bannerIndicatorDescription)
                .font(.compound.bodySM)
                .foregroundColor(.compound.textActionAccent)
                .lineLimit(1)
            Text(pinContent)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
    }
}

struct PinnedItemsBannerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        PinnedItemsBannerView(pinIndex: 0,
                              pinsCount: 3,
                              pinContent: .init(stringLiteral: "Content"),
                              onMainButtonTap: { },
                              onViewAllButtonTap: { })
    }
}
