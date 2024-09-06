//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
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
                                onSeek(max(0, min(progress, 1.0)))
                            }
                        )
                        .offset(x: -cursorInteractiveSize / 2, y: 0)
                }
                .gesture(SpatialTapGesture()
                    .onEnded { tapGesture in
                        let progress = tapGesture.location.x / geometry.size.width
                        onSeek(max(0, min(progress, 1.0)))
                    })
        }
        .coordinateSpace(name: Self.namespaceName)
        .animation(nil, value: progress)
    }

    private static let namespaceName = "voice-message-waveform"
}
