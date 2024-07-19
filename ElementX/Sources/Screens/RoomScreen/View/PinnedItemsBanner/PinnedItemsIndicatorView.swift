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
        let remainingPins = pinsCount - pinIndex
        return remainingPins >= 3 ? 3 : pinsCount % 3
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
    static var previews: some View {
        HStack(spacing: 10) {
            PinnedItemsIndicatorView(pinIndex: 0, pinsCount: 1)
            PinnedItemsIndicatorView(pinIndex: 0, pinsCount: 2)
            PinnedItemsIndicatorView(pinIndex: 1, pinsCount: 2)
            PinnedItemsIndicatorView(pinIndex: 0, pinsCount: 3)
            PinnedItemsIndicatorView(pinIndex: 1, pinsCount: 3)
            PinnedItemsIndicatorView(pinIndex: 2, pinsCount: 3)
            PinnedItemsIndicatorView(pinIndex: 0, pinsCount: 5)
            PinnedItemsIndicatorView(pinIndex: 1, pinsCount: 5)
            PinnedItemsIndicatorView(pinIndex: 2, pinsCount: 5)
            PinnedItemsIndicatorView(pinIndex: 3, pinsCount: 5)
            PinnedItemsIndicatorView(pinIndex: 4, pinsCount: 5)
            PinnedItemsIndicatorView(pinIndex: 3, pinsCount: 4)
        }
        .previewLayout(.sizeThatFits)
    }
}
