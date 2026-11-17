//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    func waveformInteraction(isDragging: Binding<Bool>, progress: Double, showCursor: Bool, onSeek: @escaping (Double) -> Void) -> some View {
        modifier(WaveformInteractionModifier(isDragging: isDragging, progress: progress, showCursor: showCursor, onSeek: onSeek))
    }
}

/// Reports up the view hierarchy that a waveform is being scrubbed, so that ancestors (such as the
/// message bubble) can stop their own gestures (e.g. the long press) from taking over the drag.
nonisolated struct WaveformScrubbingPreferenceKey: PreferenceKey {
    static let defaultValue = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct WaveformInteractionModifier: ViewModifier {
    @Binding var isDragging: Bool
    let progress: Double
    let showCursor: Bool
    let onSeek: (Double) -> Void
    
    @ScaledMetric private var cursorVisibleWidth = 2.0
    @ScaledMetric private var cursorVisibleHeight = 24.0
    private let cursorFrameSize: CGFloat = 50
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .progressCursor(progress: progress) {
                    WaveformCursorView(color: .compound.iconAccentTertiary)
                        .frame(width: cursorVisibleWidth, height: cursorVisibleHeight)
                        .opacity(showCursor ? 1 : 0)
                        .frame(width: cursorFrameSize)
                        .frame(maxHeight: cursorFrameSize)
                        .offset(x: -cursorFrameSize / 2, y: 0)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture()
                    .onEnded { tapGesture in
                        seek(to: tapGesture.location.x, width: geometry.size.width)
                    })
                // Scrub from anywhere on the waveform, not just from the cursor.
                .gesture(WaveformScrubGestureRepresentable { state, location in
                    switch state {
                    case .began, .changed:
                        isDragging = true
                        seek(to: location.x, width: geometry.size.width)
                    default:
                        isDragging = false
                    }
                })
        }
        .animation(nil, value: progress)
        .preference(key: WaveformScrubbingPreferenceKey.self, value: isDragging)
    }
    
    private func seek(to locationX: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        onSeek(max(0, min(locationX / width, 1.0)))
    }
}

/// A pan for scrubbing the waveform that only begins when the drag is mostly horizontal, so that vertical
/// drags still scroll the timeline. Other horizontal pans (e.g. swipe to reply) wait for it to fail first.
private struct WaveformScrubGestureRepresentable: UIGestureRecognizerRepresentable {
    var handle: (UIGestureRecognizer.State, CGPoint) -> Void
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer.state, context.converter.localLocation)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            
            let velocity = panRecognizer.velocity(in: gestureRecognizer.view)
            return abs(velocity.x) > abs(velocity.y)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Let scrubbing start even if the message's long press has already begun.
            // The message bubble cancels the long press as soon as scrubbing starts.
            otherGestureRecognizer is UILongPressGestureRecognizer
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            otherGestureRecognizer is UIPanGestureRecognizer && !(otherGestureRecognizer.view is UIScrollView)
        }
    }
}
