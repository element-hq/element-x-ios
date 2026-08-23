//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LongPressWithFeedback: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var triggerTask: Task<Void, Never>?
    @State private var isLongPressing = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    func body(content: Content) -> some View {
        mainContent(content: content)
            .gesture(LongPressGestureRepresentable(isEnabled: isEnabled) { gesture in
                switch gesture.state {
                case .began:
                    handleLongPress(isPressing: true)
                case .ended, .cancelled, .failed:
                    handleLongPress(isPressing: false)
                case .possible, .changed:
                    break
                @unknown default:
                    break
                }
            })
    }
    
    /// The gesture's minimum duration doesn't actually invoke the perform block when elapsed (thus
    /// the implementation below) but it does cancel other system gestures e.g. swipe to reply
    private func handleLongPress(isPressing: Bool) {
        isLongPressing = isPressing
        
        guard isLongPressing else {
            triggerTask?.cancel()
            return
        }
        
        feedbackGenerator.prepare()
        
        triggerTask = Task {
            // The wait time needs to be at least 0.5 seconds or the long press gesture will take precedence over long pressing links.
            try? await Task.sleep(for: .seconds(0.5))
            
            if Task.isCancelled {
                return
            }
            
            action()
            feedbackGenerator.impactOccurred()
        }
    }
    
    private func mainContent(content: Content) -> some View {
        content
            .compositingGroup() // Apply the shadow to the view as a whole.
            .shadow(color: .black.opacity(isLongPressing ? 0.2 : 0.0), radius: isLongPressing ? 12 : 0)
            .shadow(color: .black.opacity(isLongPressing ? 0.1 : 0.0), radius: isLongPressing ? 3 : 0)
            .scaleEffect(x: isLongPressing ? 1.05 : 1,
                         y: isLongPressing ? 1.05 : 1)
            .animation(.spring(response: 0.7).delay(isLongPressing ? 0.1 : 0).disabledDuringTests(),
                       value: isLongPressing)
    }
}

extension View {
    func longPressWithFeedback(isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        modifier(LongPressWithFeedback(isEnabled: isEnabled, action: action))
    }
    
    /// A double tap, recognised by UIKit so that it also fires over a bubble's text views (whose
    /// own tap recognisers eat a SwiftUI double tap), without delaying anyone's single tap.
    func onDoubleTap(isEnabled: Bool = true, perform action: @escaping () -> Void) -> some View {
        gesture(DoubleTapGestureRepresentable(isEnabled: isEnabled, action: action))
    }
}

/// Timing diagnostics for the double-tap reaction picker: when the double tap was
/// recognised, so downstream stages can log their latency relative to it.
@MainActor
enum DoubleTapTiming {
    static var recognised: Date?

    static func log(_ stage: String) {
        guard let recognised else { return }
        MXLog.info("Reaction picker timing: \(stage) +\(Int(Date().timeIntervalSince(recognised) * 1000))ms after double tap")
    }
}

private struct DoubleTapGestureRepresentable: UIGestureRecognizerRepresentable {
    let isEnabled: Bool
    let action: () -> Void
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = 2
        gesture.delegate = context.coordinator
        gesture.isEnabled = isEnabled
        return gesture
    }
    
    func updateUIGestureRecognizer(_ recognizer: UITapGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UITapGestureRecognizer, context: Context) {
        guard recognizer.state == .ended else { return }
        DoubleTapTiming.recognised = Date()
        MainThreadSampler.start(duration: 0.8, label: "reaction-picker")
        action()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        // Alongside the text views' taps (links) and the scroll view, never instead of them.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

struct LongPressWithFeedback_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Preview()
    }
    
    struct Preview: View {
        private let viewModel = TimelineViewModel.mock
        @State private var isPresentingSheet = false
        
        var body: some View {
            ElementNavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        mockBubble("This is a message from somebody with a couple of lines of text.")
                            .longPressWithFeedback { isPresentingSheet = true }
                        
                        mockBubble("Short message")
                            .longPressWithFeedback { isPresentingSheet = true }
                        
                        mockBubble("How are you today? The sun is shining here and its very hot ☀️☀️☀️")
                            .longPressWithFeedback { isPresentingSheet = true }
                        
                        mockBubble("I'm a fake!")
                            .contextMenu {
                                Button("Copy") { }
                                Button("Reply") { }
                                Button("Remove") { }
                            }
                    }
                    .padding()
                }
                .navigationTitle("Work chat")
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $isPresentingSheet) {
                Text("Long pressed!")
                    .presentationDetents([.medium])
            }
            .environmentObject(viewModel.context)
        }
        
        func mockBubble(_ body: String) -> some View {
            Text(body)
                .bubbleBackground()
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                .onTapGesture { /* Fix long press gesture blocking the scroll view */ }
        }
    }
}

/// Fixes the issue on iOS 18 where LongPress conflicts with the scroll view
/// https://github.com/feedback-assistant/reports/issues/542#issuecomment-2581322968
private struct LongPressGestureRepresentable: UIGestureRecognizerRepresentable {
    var isEnabled = true
    var handle: (UILongPressGestureRecognizer) -> Void
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.25
        gesture.delegate = context.coordinator
        gesture.isEnabled = isEnabled
        return gesture
    }
    
    func updateUIGestureRecognizer(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        handle(recognizer)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
