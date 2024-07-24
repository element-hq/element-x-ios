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
