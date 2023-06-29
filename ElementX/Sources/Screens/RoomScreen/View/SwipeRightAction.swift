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
            .gesture(DragGesture()
                .updating($dragGestureActive) { _, state, _ in
                    // Available actions should be computed on the fly so we use a gesture state change
                    // to ask whether the move should be started or not.
                    state = true
                }
                .onChanged { value in
                    guard canStartAction else {
                        return
                    }
                    
                    // We want to add a spring like behavior to the drag in which the view
                    // moves slower the more it's dragged. We use a circular easing function
                    // to generate those values up to the `swipeThreshold`
                    // The final translation will be between 0 and `swipeThreshold` with the action being enabled from
                    // `actionThreshold` onwards
                    let screenWidthNormalisedTranslation = max(0.0, min(value.translation.width, swipeThreshold)) / swipeThreshold
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
            )
            .onChange(of: dragGestureActive, perform: { value in
                if value == true {
                    if shouldStartAction() {
                        feedbackGenerator.prepare()
                        canStartAction = true
                    }
                }
            })
            .overlay(alignment: .leading) {
                // We want the action icon to follow the view translation and gradually fade in
                label()
                    .opacity(xOffset / 50)
                    .animation(.interactiveSpring().speed(0.5), value: xOffset)
                    .offset(x: -actionThreshold + min(xOffset, actionThreshold), y: 0.0)
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

struct SwipeRightAction_Previews: PreviewProvider {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        @State private var isPresentingSheet = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading) {
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
