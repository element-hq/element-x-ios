//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct PinnedItemsIndicatorView: View {
    let pinIndex: Int
    let pinsCount: Int
    
    private var activeIndex: Int {
        pinIndex % 3
    }
    
    private var shownIndicators: Int {
        if pinsCount <= 3 {
            return pinsCount
        }
        let maxUntruncatedIndicators = pinsCount - pinsCount % 3
        if pinIndex < maxUntruncatedIndicators {
            return 3
        }
        return pinsCount % 3
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(index == activeIndex ? Color.compound.iconAccentPrimary : Color.compound._borderInteractiveSecondaryAlpha)
                    .scaledFrame(width: 2, height: 11)
                    .opacity(index < shownIndicators ? 1 : 0)
            }
        }
    }
}

struct PinnedItemsIndicatorView_Previews: PreviewProvider, TestablePreview {
    static func indicator(index: Int, count: Int) -> some View {
        VStack(spacing: 0) {
            Text("\(index + 1)/\(count)")
                .font(.compound.bodyXS)
            PinnedItemsIndicatorView(pinIndex: index, pinsCount: count)
        }
    }
    
    static var previews: some View {
        HStack(spacing: 5) {
            indicator(index: 0, count: 1)
            indicator(index: 0, count: 2)
            indicator(index: 1, count: 2)
            indicator(index: 0, count: 3)
            indicator(index: 1, count: 3)
            indicator(index: 2, count: 3)
            indicator(index: 0, count: 4)
            indicator(index: 1, count: 4)
            indicator(index: 2, count: 4)
            indicator(index: 3, count: 4)
            indicator(index: 0, count: 5)
            indicator(index: 1, count: 5)
            indicator(index: 2, count: 5)
            indicator(index: 3, count: 5)
            indicator(index: 4, count: 5)
        }
        .previewLayout(.sizeThatFits)
    }
}
