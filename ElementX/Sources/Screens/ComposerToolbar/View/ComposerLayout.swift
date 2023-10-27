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

struct ComposerLayout: Layout {
    struct IsComposer: LayoutValueKey {
        static let defaultValue = false
    }
    
    var spacing: CGFloat = -6
    var composerVerticalPadding: CGFloat = 10
    let composerHeight: CGFloat
    let updateMaxComposerHeight: (CGFloat) -> Void
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height = CGFloat.zero
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            if subview[IsComposer.self] {
                height += composerVerticalPadding * 2
                let idealHeight = idealComposerHeight(proposedHeight: size.height,
                                                      availableHeight: (proposal.height ?? .greatestFiniteMagnitude) - height)
                height += idealHeight
            } else {
                height += size.height
            }
            height += spacing
        }
        height -= spacing
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = CGFloat.zero
        for subview in subviews {
            var size = subview.sizeThatFits(.init(bounds.size))
            if subview[IsComposer.self] {
                y += composerVerticalPadding
                let idealHeight = idealComposerHeight(proposedHeight: size.height,
                                                      availableHeight: bounds.height - y - composerVerticalPadding)
                DispatchQueue.main.async {
                    updateMaxComposerHeight(idealHeight)
                }
                size.height = idealHeight
            }
            subview.place(at: .init(x: bounds.minX, y: y + bounds.minY), proposal: .init(width: proposal.width, height: size.height))
            y += size.height + spacing
        }
    }
    
    func idealComposerHeight(proposedHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        min(max(composerHeight, proposedHeight), availableHeight)
    }
}

struct ComposerLayout_Previews: PreviewProvider {
    static var previews: some View {
        ComposerLayout(spacing: 0, composerHeight: 100) { _ in } {
            Text("Hello")
            Text("World")
                .layoutValue(key: ComposerLayout.IsComposer.self, value: true)
        }
        .border(.purple)
        VStack {
            ComposerLayout(spacing: 0, composerHeight: 100) { _ in } {
                Color.red
                    .frame(height: 50)
                Text("World")
                    .layoutValue(key: ComposerLayout.IsComposer.self, value: true)
            }
            .border(.purple)
            Rectangle()
                .fill(Color.blue)
                .frame(height: 730)
        }
    }
}
