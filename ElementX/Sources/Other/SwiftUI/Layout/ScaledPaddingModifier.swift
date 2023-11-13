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

extension View {
    func scaledPadding(_ length: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        scaledPadding(.all, length, relativeTo: textStyle)
    }
    
    func scaledPadding(_ edges: Edge.Set, _ length: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledFontModifier(edges: edges, length: length, textStyle: textStyle))
    }
}

private struct ScaledFontModifier: ViewModifier {
    let edges: Edge.Set
    @ScaledMetric var length: CGFloat
    
    init(edges: Edge.Set, length: CGFloat, textStyle: Font.TextStyle) {
        self.edges = edges
        _length = ScaledMetric(wrappedValue: length, relativeTo: textStyle)
    }
    
    func body(content: Content) -> some View {
        content.padding(edges, length)
    }
}
