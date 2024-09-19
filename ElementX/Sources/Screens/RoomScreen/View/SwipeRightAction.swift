//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SwipeRightAction<Label: View>: ViewModifier {
    private let actionThreshold = 50.0
    private let xOffsetThreshold = 100.0
    private let swipeThreshold = 1000.0
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    @State private var canStartAction = false
    @GestureState private var dragGestureActive = false
    
    @State private var hasReachedActionThreshold = false
    @State private var xOffset = 0.0
    
    /// The view to be shown on the left side of the content
    let label: () -> Label
    /// Defer computing whether an action is available until the gesture is started
    let shouldStartAction: () -> Bool
    /// Callback for when the dragged past the action threshold
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .offset(x: xOffset, y: 0.0)
            .animation(.interactiveSpring().speed(0.5), value: xOffset)
            .simultaneousGesture(gesture)
            .onChange(of: dragGestureActive) { value in
                if value == true {
                    if shouldStartAction() {
                        feedbackGenerator.prepare()
                        canStartAction = true
                    }
                }
            }
            .overlay(alignment: .leading) {
                // We want the action icon to follow the view translation and gradually fade in
                label()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: actionThreshold)
                    .opacity(xOffset / 50)
                    .animation(.interactiveSpring().speed(0.5), value: xOffset)
                    .offset(x: -actionThreshold + min(xOffset, actionThreshold), y: 0.0)
            }
    }
    
    private var gesture: some Gesture {
        DragGesture()
            .updating($dragGestureActive) { _, state, _ in
                // Available actions should be computed on the fly so we use a gesture state change
                // to ask whether the move should be started or not.
                state = true
            }
            .onChanged { value in
                guard canStartAction, value.translation.width > value.translation.height else {
                    return
                }
                
                // Due to https://forums.developer.apple.com/forums/thread/760035 we had to make
                // the drag a simultaneous gesture otherwise it was impossible to scroll the timeline.
                // Therefore we need to prevent the animation to run if the user is to scrolling vertically.
                // It would be nice if we could somehow abort the gesture in this case.
                let width: CGFloat = if value.translation.width > abs(value.translation.height) {
                    value.translation.width
                } else {
                    0.0
                }
                
                // We want to add a spring like behaviour to the drag in which the view
                // moves slower the more it's dragged. We use a circular easing function
                // to generate those values up to the `swipeThreshold`
                // The final translation will be between 0 and `swipeThreshold` with the action being enabled from
                // `actionThreshold` onwards
                let screenWidthNormalisedTranslation = max(0.0, min(width, swipeThreshold)) / swipeThreshold
                let easedTranslation = circularEaseOut(screenWidthNormalisedTranslation)
                xOffset = easedTranslation * xOffsetThreshold
                
                if xOffset > actionThreshold {
                    if !hasReachedActionThreshold {
                        feedbackGenerator.impactOccurred()
                        hasReachedActionThreshold = true
                    }
                } else {
                    hasReachedActionThreshold = false
                }
            }
            .onEnded { _ in
                if xOffset > actionThreshold {
                    action()
                }
                
                xOffset = 0.0
            }
    }
    
    /// Used to compute the horizontal translation amount.
    /// The more it's dragged the less it moves on a circular ease out curve
    private func circularEaseOut(_ value: Double) -> Double {
        sqrt((2 - value) * value)
    }
}

extension View {
    func swipeRightAction(label: @escaping () -> some View,
                          shouldStartAction: @escaping () -> Bool,
                          action: @escaping () -> Void) -> some View {
        modifier(SwipeRightAction(label: label, shouldStartAction: shouldStartAction, action: action))
    }
}

struct SwipeRightAction_Previews: PreviewProvider, TestablePreview {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        @State private var isPresentingSheet = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        mockBubble("This is a message from somebody with a couple of lines of text.")
                            .swipeRightAction {
                                Image(systemName: "flame")
                            } shouldStartAction: {
                                true
                            } action: {
                                isPresentingSheet = true
                            }
                    }
                    .padding()
                }
                .navigationTitle("Work chat")
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $isPresentingSheet) {
                Text("Action triggered!")
                    .presentationDetents([.medium])
            }
        }
        
        func mockBubble(_ body: String) -> some View {
            Text(body)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.compound._bgBubbleOutgoing, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
