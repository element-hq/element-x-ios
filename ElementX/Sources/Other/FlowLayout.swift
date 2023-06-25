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

struct FlowLayout: Layout {
    enum Alignment {
        case leading
        case trailing
    }
    
    let alignment: Alignment
    
    init(alignment: Alignment = .leading) {
        self.alignment = alignment
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width
                lineHeight = max(lineHeight, size.height)
            }
            
            totalWidth = max(totalWidth, lineWidth)
        }
        
        totalHeight += lineHeight
        
        return .init(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var lineX: CGFloat = alignment == .leading ? bounds.minX : bounds.maxX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            if alignment == .leading && lineX + sizes[index].width > (proposal.width ?? 0) ||
                alignment == .trailing && lineX - sizes[index].width < 0 {
                lineY += lineHeight
                lineHeight = 0
                lineX = alignment == .leading ? bounds.minX : bounds.maxX
            }

            let point: CGPoint = .init(x: lineX, y: lineY + sizes[index].height / 2)
            let anchor: UnitPoint = alignment == .leading ? .leading : .trailing
            subviews[index].place(at: point, anchor: anchor, proposal: ProposedViewSize(sizes[index]))
            lineHeight = max(lineHeight, sizes[index].height)
            if alignment == .leading {
                lineX += sizes[index].width
            } else {
                lineX -= sizes[index].width
            }
        }
    }
}
