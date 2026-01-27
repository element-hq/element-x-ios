//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LongPressWithFeedback: ViewModifier {
    let action: () -> Void
    
    @State private var triggerTask: Task<Void, Never>?
    @State private var isLongPressing = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    func body(content: Content) -> some View {
        mainContent(content: content)
            .gesture(LongPressGestureRepresentable { gesture in
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
    func longPressWithFeedback(action: @escaping () -> Void) -> some View {
        modifier(LongPressWithFeedback(action: action))
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
            NavigationStack {
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
    var handle: (UILongPressGestureRecognizer) -> Void
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.25
        gesture.delegate = context.coordinator
        gesture.isEnabled = true
        return gesture
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
