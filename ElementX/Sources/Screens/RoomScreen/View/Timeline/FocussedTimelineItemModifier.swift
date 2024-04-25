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

extension View {
    func highlightedTimelineItem(_ isHighlighted: Bool) -> some View {
        modifier(HighlightedTimelineItemModifier(isHighlighted: isHighlighted))
    }
}

private struct HighlightedTimelineItemModifier: ViewModifier {
    let isHighlighted: Bool
    
    func body(content: Content) -> some View {
        content
            .background {
                if isHighlighted {
                    VStack(spacing: 0) {
                        Color.compound._bgBubbleHighlighted
                        LinearGradient(colors: [.compound._bgBubbleHighlighted, .clear],
                                       startPoint: .top,
                                       endPoint: .bottom)
                            .frame(maxHeight: 200)
                            .layoutPriority(1)
                    }
                    .overlay(alignment: .top) {
                        Color.compound.bgAccentRest
                            .frame(height: 1)
                    }
                }
            }
    }
}
