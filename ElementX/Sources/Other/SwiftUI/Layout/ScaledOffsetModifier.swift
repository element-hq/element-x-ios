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

extension View {
    func scaledOffset(x: CGFloat = 0, y: CGFloat = 0, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledOffsetModifier(x: x, y: y, relativeTo: textStyle))
    }
}

private struct ScaledOffsetModifier: ViewModifier {
    @ScaledMetric var x: CGFloat
    @ScaledMetric var y: CGFloat
    
    init(x: CGFloat, y: CGFloat, relativeTo: Font.TextStyle) {
        _x = ScaledMetric(wrappedValue: x, relativeTo: relativeTo)
        _y = ScaledMetric(wrappedValue: y, relativeTo: relativeTo)
    }
    
    func body(content: Content) -> some View {
        content.offset(x: x, y: y)
    }
}
