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

struct WaveformViewDragGestureModifier: ViewModifier {
    @GestureState private var dragGestureState = WaveformViewDragState.inactive
    @Binding var dragState: WaveformViewDragState
    
    let minimumDragDistance: Double
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .gesture(SpatialTapGesture()
                    .simultaneously(with: LongPressGesture())
                    .sequenced(before: DragGesture(minimumDistance: minimumDragDistance, coordinateSpace: .local))
                    .updating($dragGestureState) { value, state, _ in
                        switch value {
                        // (SpatialTap, LongPress) begins.
                        case .first(let spatialLongPress):
                            // Compute the progress with the spatialTap location
                            let progress = (spatialLongPress.first?.location ?? .zero).x / geometry.size.width
                            state = .pressing(progress: progress)
                        // Long press confirmed, dragging may begin.
                        case .second(let spatialLongPress, let drag) where spatialLongPress.second ?? false:
                            var progress: Double = dragState.progress
                            // Compute the progress with drag location
                            if let loc = drag?.location {
                                progress = loc.x / geometry.size.width
                            }
                            state = .dragging(progress: progress)
                        // Dragging ended or the long press cancelled.
                        default:
                            state = .inactive
                        }
                    })
        }
        .onChange(of: dragGestureState) { value in
            dragState = value
        }
    }
}

extension View {
    func waveformDragGesture(_ dragState: Binding<WaveformViewDragState>, minimumDragDistance: Double = 0) -> some View {
        modifier(WaveformViewDragGestureModifier(dragState: dragState,
                                                 minimumDragDistance: minimumDragDistance))
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
    
    var isActive: Bool {
        switch self {
        case .inactive:
            return false
        case .pressing, .dragging:
            return true
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
