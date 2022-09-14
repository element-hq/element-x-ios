//
// Copyright 2022 New Vector Ltd
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

struct MessageComposer: View {
    @Binding var text: String
    @Binding var focused: Bool
    let sendingDisabled: Bool
    let type: RoomScreenComposerType
    
    let sendAction: () -> Void
    let replyCancellationAction: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom) {
            let rect = RoundedRectangle(cornerRadius: 8.0)
            VStack(alignment: .leading, spacing: 2.0) {
                if case let .reply(_, displayName) = type {
                    HStack(alignment: .center) {
                        Text("\(Image(systemName: "arrow.uturn.left")) \(ElementL10n.roomTimelineReplyingTo(displayName))")
                            .font(.element.caption2)
                            .foregroundColor(.element.secondaryContent)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            replyCancellationAction()
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12.0, height: 12.0)
                                .padding(4.0)
                        }
                    }
                }
                MessageComposerTextField(placeholder: "Send a message",
                                         text: $text,
                                         focused: $focused,
                                         maxHeight: 300)
            }
            .padding(4.0)
            .frame(minHeight: 44.0)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
            .animation(.elementDefault, value: type)
            .animation(.elementDefault, value: borderWidth)

            Button {
                sendAction()
            } label: {
                Image(uiImage: Asset.Images.timelineComposerSendMessage.image)
                    .background(Circle()
                        .foregroundColor(.global.white)
                    )
            }
            .padding(.bottom, 6.0)
            .disabled(sendingDisabled)
            .opacity(sendingDisabled ? 0.5 : 1.0)
            .animation(.elementDefault, value: sendingDisabled)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }
    
    private var borderColor: Color {
        .element.accent
    }
    
    private var borderWidth: CGFloat {
        focused ? 2.0 : 1.0
    }
}

struct MessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack {
            MessageComposer(text: .constant(""),
                            focused: .constant(false),
                            sendingDisabled: true,
                            type: .default,
                            sendAction: { },
                            replyCancellationAction: { })
            
            MessageComposer(text: .constant("Some message"),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .reply(id: UUID().uuidString,
                                         displayName: "John Doe"),
                            sendAction: { },
                            replyCancellationAction: { })
        }
        .tint(.element.accent)
    }
}
