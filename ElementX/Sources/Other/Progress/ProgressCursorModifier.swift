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

import Compound
import SwiftUI

extension View {
    func progressCursor<CursorView: View>(progress: CGFloat,
                                          @ViewBuilder cursorView: @escaping () -> CursorView) -> some View {
        modifier(ProgressCursorModifier(progress: progress,
                                        cursorView: cursorView))
    }
}

private struct ProgressCursorModifier<CursorView: View>: ViewModifier {
    let progress: CGFloat
    @ViewBuilder var cursorView: () -> CursorView
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .overlay(alignment: .leading) {
                    cursorView()
                        .offset(CGSize(width: progress * geometry.size.width, height: 0.0))
                        .frame(height: geometry.size.height)
                }
        }
    }
}
