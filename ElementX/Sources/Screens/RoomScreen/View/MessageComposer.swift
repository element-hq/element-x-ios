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
    let type: RoomScreenComposerMode
    
    let sendAction: () -> Void
    let replyCancellationAction: () -> Void
    let editCancellationAction: () -> Void
    
    var body: some View {
        let roundedRectangle = RoundedRectangle(cornerRadius: borderRadius)
        VStack(alignment: .leading, spacing: 0) {
            header
            HStack(alignment: .bottom) {
                MessageComposerTextField(placeholder: ElementL10n.roomMessagePlaceholder,
                                         text: $text,
                                         focused: $focused,
                                         maxHeight: 300,
                                         onEnterKeyHandler: sendAction)
                    .tint(.element.brand)
                    .padding(.vertical, 12)
                
                Button {
                    sendAction()
                } label: {
                    submitButtonImage
                        .symbolVariant(.fill)
                        .font(.element.body)
                        .foregroundColor(sendingDisabled ? .element.quaternaryContent : .element.background)
                        .padding(5)
                        .background {
                            Circle()
                                .foregroundColor(sendingDisabled ? .clear : .element.brand)
                        }
                }
                .disabled(sendingDisabled)
                .animation(.elementDefault, value: sendingDisabled)
                .keyboardShortcut(.return, modifiers: [.command])
                .padding(8)
            }
        }
        .padding(.leading, 12.0)
        .background {
            ZStack {
                roundedRectangle
                    .fill(Color.element.system)
                roundedRectangle
                    .stroke(Color.element.quinaryContent, lineWidth: 1)
                    .opacity(focused ? 1 : 0)
            }
        }
        .clipShape(roundedRectangle)
        .animation(.elementDefault, value: type)
    }

    @ViewBuilder
    private var header: some View {
        switch type {
        case .reply(_, let displayName):
            MessageComposerReplyHeader(displayName: displayName, action: replyCancellationAction)
        case .edit:
            MessageComposerEditHeader(action: editCancellationAction)
        case .default:
            EmptyView()
        }
    }
    
    private var submitButtonImage: some View {
        // ZStack with opacity so the button size is consistent.
        ZStack {
            Image(systemName: "checkmark")
                .opacity(type.isEdit ? 1 : 0)
                .fontWeight(.medium)
            Image(systemName: "paperplane")
                .opacity(type.isEdit ? 0 : 1)
        }
    }
    
    private var borderRadius: CGFloat {
        switch type {
        case .default:
            return 28.0
        case .reply, .edit:
            return 12.0
        }
    }
}

private struct MessageComposerReplyHeader: View {
    let displayName: String
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Label(ElementL10n.roomTimelineReplyingTo(displayName), systemImage: "arrowshape.turn.up.left")
                .font(.element.caption1)
                .foregroundColor(.element.secondaryContent)
                .lineLimit(1)
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: "xmark")
                    .font(.element.caption2.weight(.medium))
                    .foregroundColor(.element.secondaryContent)
                    .padding(12.0)
            }
        }
    }
}

private struct MessageComposerEditHeader: View {
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Label(ElementL10n.roomTimelineEditing, systemImage: "pencil.line")
                .font(.element.caption1)
                .foregroundColor(.element.secondaryContent)
                .lineLimit(1)
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: "xmark")
                    .font(.element.caption2.weight(.medium))
                    .foregroundColor(.element.secondaryContent)
                    .padding(12.0)
            }
        }
    }
}

struct MessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageComposer(text: .constant(""),
                            focused: .constant(false),
                            sendingDisabled: true,
                            type: .default,
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is a short message."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .default,
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is a very long message that will wrap to 2 lines on an iPhone 14."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .default,
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is an even longer message that will wrap to 3 lines on an iPhone 14, just to see the difference it makes."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .default,
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("Some message"),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .reply(id: UUID().uuidString,
                                         displayName: "John Doe"),
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })

            MessageComposer(text: .constant("Some message"),
                            focused: .constant(false),
                            sendingDisabled: false,
                            type: .edit(originalItemId: UUID().uuidString),
                            sendAction: { },
                            replyCancellationAction: { },
                            editCancellationAction: { })
        }
        .tint(.element.accent)
        .padding(.horizontal)
    }
}
