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
    func scaledFrame(width: CGFloat, height: CGFloat, alignment: Alignment = .center, relativeTo textStyle: Font.TextStyle? = nil) -> some View {
        modifier(ScaledFrameModifier(width: width, height: height, alignment: alignment, relativeTo: textStyle))
    }
}

private struct ScaledFrameModifier: ViewModifier {
    @ScaledMetric var width: CGFloat
    @ScaledMetric var height: CGFloat
    let alignment: Alignment
    
    init(width: CGFloat, height: CGFloat, alignment: Alignment, relativeTo textStyle: Font.TextStyle?) {
        _width = ScaledMetric(wrappedValue: width, relativeTo: textStyle)
        _height = ScaledMetric(wrappedValue: height, relativeTo: textStyle)
        self.alignment = alignment
    }
    
    func body(content: Content) -> some View {
        content.frame(width: width, height: height, alignment: alignment)
    }
}

extension ScaledMetric {
    init(wrappedValue: Value, relativeTo textStyle: Font.TextStyle?) {
        self = textStyle.map { .init(wrappedValue: wrappedValue, relativeTo: $0) } ?? .init(wrappedValue: wrappedValue)
    }
}
