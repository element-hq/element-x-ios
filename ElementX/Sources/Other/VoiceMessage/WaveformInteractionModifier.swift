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
    func waveformInteraction(isDragging: GestureState<Bool>, progress: Double, showCursor: Bool, onSeek: @escaping (Double) -> Void) -> some View {
        modifier(WaveformInteractionModifier(isDragging: isDragging, progress: progress, showCursor: showCursor, onSeek: onSeek))
    }
}

private struct WaveformInteractionModifier: ViewModifier {
    let isDragging: GestureState<Bool>
    let progress: Double
    let showCursor: Bool
    let onSeek: (Double) -> Void

    @ScaledMetric private var cursorVisibleWidth = 2.0
    @ScaledMetric private var cursorVisibleHeight = 24.0
    private let cursorInteractiveSize: CGFloat = 50
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .gesture(SpatialTapGesture()
                    .onEnded { tapGesture in
                        let progress = tapGesture.location.x / geometry.size.width
                        feedbackGenerator.selectionChanged()
                        onSeek(max(0, min(progress, 1.0)))
                    })
                .progressCursor(progress: progress) {
                    WaveformCursorView(color: .compound.iconAccentTertiary)
                        .frame(width: cursorVisibleWidth, height: cursorVisibleHeight)
                        .opacity(showCursor ? 1 : 0)
                        .frame(width: cursorInteractiveSize)
                        .frame(maxHeight: cursorInteractiveSize)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(coordinateSpace: .named(Self.namespaceName))
                            .updating(isDragging) { dragGesture, isDragging, _ in
                                isDragging = true
                                let progress = dragGesture.location.x / geometry.size.width
                                feedbackGenerator.selectionChanged()
                                onSeek(max(0, min(progress, 1.0)))
                            }
                        )
                        .offset(x: -cursorInteractiveSize / 2, y: 0)
                }
        }
        .coordinateSpace(name: Self.namespaceName)
    }

    private static let namespaceName = "voice-message-waveform"
}
