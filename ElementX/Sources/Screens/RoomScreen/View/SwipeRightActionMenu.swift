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

struct SwipeRightActionMenu: ViewModifier {
    private let actionThreshold = 50.0
    private let translationThreshold = 100.0
    private let swipeThreshold = 1000.0
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    @State private var canStartAction = false
    @GestureState private var dragGestureActive = false
    
    @State private var hasReachedActionThreshold = false
    @State private var iconOpacity = 0.0
    @State private var xAxisTranslation = 0.0 {
        didSet {
            iconOpacity = xAxisTranslation / 50
        }
    }
    
    let actionIconSystemName: String
    let shouldStartAction: () -> Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .offset(x: xAxisTranslation, y: 0.0)
            .animation(.interactiveSpring().speed(0.5), value: xAxisTranslation)
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
                    let easedTranslation = circularEaseOut(p: screenWidthNormalisedTranslation)
                    xAxisTranslation = easedTranslation * translationThreshold
                    
                    if xAxisTranslation > actionThreshold {
                        if !hasReachedActionThreshold {
                            feedbackGenerator.impactOccurred()
                            hasReachedActionThreshold = true
                        }
                    } else {
                        hasReachedActionThreshold = false
                    }
                }
                .onEnded { _ in
                    if xAxisTranslation > actionThreshold {
                        action()
                    }
                    
                    xAxisTranslation = 0.0
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
                Image(systemName: actionIconSystemName)
                    .opacity(iconOpacity)
                    .animation(.interactiveSpring().speed(0.5), value: xAxisTranslation)
                    .offset(x: -actionThreshold + min(xAxisTranslation, actionThreshold), y: 0.0)
            }
    }
    
    /// Used to compute the horizontal translation amount.
    /// The more it's dragged the less it moves on a circular ease out curve
    private func circularEaseOut(p: Double) -> Double {
        sqrt((2 - p) * p)
    }
}

extension View {
    func swipeRightActionMenu(actionIconSystemName: String,
                              shouldStartAction: @escaping () -> Bool,
                              action: @escaping () -> Void) -> some View {
        modifier(SwipeRightActionMenu(actionIconSystemName: actionIconSystemName, shouldStartAction: shouldStartAction, action: action))
    }
}

struct SwipeRightActionMenu_Previews: PreviewProvider {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        private let viewModel = RoomScreenViewModel.mock
        @State private var isPresentingSheet = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        mockBubble("This is a message from somebody with a couple of lines of text.")
                            .swipeRightActionMenu(actionIconSystemName: "flame") {
                                true
                            } action: {
                                isPresentingSheet = true
                            }
                        
                        mockBubble("Short message")
                            .swipeRightActionMenu(actionIconSystemName: "flame") {
                                true
                            } action: {
                                isPresentingSheet = true
                            }
                        
                        mockBubble("How are you today? The sun is shining here and its very hot ☀️☀️☀️")
                            .swipeRightActionMenu(actionIconSystemName: "flame") {
                                true
                            } action: {
                                isPresentingSheet = true
                            }
                        
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
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.compound._bgBubbleOutgoing, in: RoundedRectangle(cornerRadius: 12))
                .onTapGesture { /* Fix long press gesture blocking the scroll view */ }
        }
    }
}
