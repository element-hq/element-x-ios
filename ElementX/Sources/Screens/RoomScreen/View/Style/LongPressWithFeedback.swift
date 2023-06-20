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
    
    @State private var isLongPressing = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: isLongPressing ? 0.93 : 1,
                         y: isLongPressing ? 0.93 : 1)
            .animation(isLongPressing ? .spring(response: 0.8).delay(0.2) : .spring(response: 0.2),
                       value: isLongPressing)
            .onLongPressGesture(minimumDuration: 0.25) {
                action()
                feedbackGenerator.impactOccurred()
            } onPressingChanged: { isPressing in
                isLongPressing = isPressing
                if isPressing {
                    feedbackGenerator.prepare()
                }
            }
    }
}

extension View {
    func longPressWithFeedback(action: @escaping () -> Void) -> some View {
        modifier(LongPressWithFeedback(action: action))
    }
}

struct FakeContextMenu_Previews: PreviewProvider {
    static var previews: some View { Preview() }
    
    struct Preview: View {
        private let viewModel = RoomScreenViewModel.mock
        @State private var isPresentingSheet = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading) {
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
                .onTapGesture { /* Fix long press gesture blocking the scroll view */ }
        }
    }
}
