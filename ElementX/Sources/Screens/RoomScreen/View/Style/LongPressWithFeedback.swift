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

struct LongPressWithFeedback: ViewModifier {
    let action: () -> Void
    
    @State private var triggerTask: Task<Void, Never>?
    @State private var isLongPressing = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    func body(content: Content) -> some View {
        content
            .compositingGroup() // Apply the shadow to the view as a whole.
            .shadow(color: .black.opacity(isLongPressing ? 0.2 : 0.0), radius: isLongPressing ? 12 : 0)
            .shadow(color: .black.opacity(isLongPressing ? 0.1 : 0.0), radius: isLongPressing ? 3 : 0)
            .scaleEffect(x: isLongPressing ? 1.05 : 1,
                         y: isLongPressing ? 1.05 : 1)
            .animation(.spring(response: 0.7).delay(isLongPressing ? 0.1 : 0).disabledDuringTests(),
                       value: isLongPressing)
            // The minimum duration here doesn't actually invoke the perform block when elapsed (thus
            // the implementation below) but it does cancel other system gestures e.g. swipe to reply
            .onLongPressGesture(minimumDuration: 0.25) { } onPressingChanged: { isPressing in
                isLongPressing = isPressing
                
                guard isPressing else {
                    triggerTask?.cancel()
                    return
                }
                
                feedbackGenerator.prepare()
                
                triggerTask = Task {
                    // The wait time needs to be at least 0.5 seconds or the long press gesture will take precedence over long pressing links.
                    try? await Task.sleep(for: .seconds(0.5))
                    
                    if Task.isCancelled { return }

                    action()
                    feedbackGenerator.impactOccurred()
                }
            }
    }
}

extension View {
    func longPressWithFeedback(action: @escaping () -> Void) -> some View {
        modifier(LongPressWithFeedback(action: action))
    }
}

struct LongPressWithFeedback_Previews: PreviewProvider, TestablePreview {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        private let viewModel = RoomScreenViewModel.mock
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
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.compound._bgBubbleOutgoing, in: RoundedRectangle(cornerRadius: 12))
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                .onTapGesture { /* Fix long press gesture blocking the scroll view */ }
        }
    }
}
