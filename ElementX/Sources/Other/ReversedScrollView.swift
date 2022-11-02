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

/// A SwiftUI scroll view that lays out its content starting at the bottom or trailing
/// https://www.thirdrocktechkno.com/blog/implementing-reversed-scrolling-behaviour-in-swiftui/
struct ReversedScrollView<Content: View>: View {
    private let axis: Axis.Set
    private let leadingSpace: CGFloat
    private let content: Content
    
    init(_ axis: Axis.Set = .horizontal, leadingSpace: CGFloat = 0, @ViewBuilder builder: () -> Content) {
        self.axis = axis
        self.leadingSpace = leadingSpace
        content = builder()
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(axis, showsIndicators: false) {
                Stack(axis) {
                    Spacer(minLength: leadingSpace)
                    content
                }
                .frame(
                    minWidth: minWidth(in: proxy, for: axis),
                    minHeight: minHeight(in: proxy, for: axis)
                )
            }
        }
    }
    
    private func minWidth(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
        axis.contains(.horizontal) ? proxy.size.width : nil
    }
    
    private func minHeight(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
        axis.contains(.vertical) ? proxy.size.height : nil
    }
}

private struct Stack<Content: View>: View {
    var axis: Axis.Set
    var content: Content
    
    init(_ axis: Axis.Set = .vertical, @ViewBuilder builder: () -> Content) {
        self.axis = axis
        
        content = builder()
    }
    
    var body: some View {
        switch axis {
        case .horizontal:
            HStack {
                content
            }
        case .vertical:
            VStack {
                content
            }
        default:
            VStack {
                content
            }
        }
    }
}
