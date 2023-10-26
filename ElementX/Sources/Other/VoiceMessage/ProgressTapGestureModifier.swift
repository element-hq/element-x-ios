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

import DSWaveformImageViews
import Foundation
import SwiftUI

#warning("Delete me?")
private struct ProgressTapGestureModifier: ViewModifier {
    @Binding var progress: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .gesture(SpatialTapGesture()
                    .onEnded { tapGesture in
                        progress = tapGesture.location.x / geometry.size.width
                    })
        }
    }
}

extension View {
    func progressTapGesture(progress: Binding<CGFloat>) -> some View {
        modifier(ProgressTapGestureModifier(progress: progress))
    }
}

enum WaveformViewDragState: Equatable {
    case inactive
    case pressing(progress: Double)
    case dragging(progress: Double)
    
    var progress: Double {
        switch self {
        case .inactive:
            return .zero
        case .pressing(let progress), .dragging(let progress):
            return progress
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .inactive, .pressing:
            return false
        case .dragging:
            return true
        }
    }
}
