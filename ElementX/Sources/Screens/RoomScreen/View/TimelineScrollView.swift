//
// Copyright 2022 New Vector Ltd
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

struct VisibleEdgesKey: PreferenceKey {
    static var defaultValue: [VerticalEdge] = []

    static func reduce(value: inout [VerticalEdge], nextValue: () -> [VerticalEdge]) {
        value = nextValue()
    }
}

/// A SwiftUI scroll view with the following customisations for a room timeline
/// - The content is laid out starting at the bottom.
/// - Top and bottom edge visibility detection for triggering other behaviours.
struct TimelineScrollView<Content: View>: View {
    @Binding var visibleEdges: [VerticalEdge]
    
    @ViewBuilder var content: () -> Content
    
    /// A small threshold added to the edge detection to allow a bit of leniency.
    private let edgeDetectionThreshold: CGFloat = 15
    
    var body: some View {
        GeometryReader { scrollViewGeometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    content()
                }
                .frame(minHeight: scrollViewGeometry.size.height)
                .background {
                    GeometryReader { contentGeometry in
                        Color.clear
                            .preference(key: VisibleEdgesKey.self,
                                        value: visibleEdges(of: contentGeometry, in: scrollViewGeometry))
                    }
                    .onPreferenceChange(VisibleEdgesKey.self) {
                        visibleEdges = $0
                    }
                }
            }
        }
    }
    
    func visibleEdges(of contentGeometry: GeometryProxy, in scrollViewGeometry: GeometryProxy) -> [VerticalEdge] {
        let frame = contentGeometry.frame(in: .global)
        let isTopVisible = scrollViewGeometry.frame(in: .global).contains(CGPoint(x: frame.midX, y: frame.minY + edgeDetectionThreshold))
        let isBottomVisible = scrollViewGeometry.frame(in: .global).contains(CGPoint(x: frame.midX, y: frame.maxY - edgeDetectionThreshold))
        
        switch (isTopVisible, isBottomVisible) {
        case (false, false):
            return []
        case (true, false):
            return [.top]
        case (false, true):
            return [.bottom]
        case (true, true):
            return [.top, .bottom]
        }
    }
}
