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
    
    @State private var isMultiline = false
    @ScaledMetric private var sendButtonIconSize = 16
    
    var body: some View {
        let roundedRectangle = RoundedRectangle(cornerRadius: borderRadius)
        VStack(alignment: .leading, spacing: -6) {
            header
            HStack(alignment: .bottom) {
                MessageComposerTextField(placeholder: L10n.richTextEditorComposerPlaceholder,
                                         text: $text,
                                         focused: $focused,
                                         isMultiline: $isMultiline,
                                         maxHeight: 300,
                                         onEnterKeyHandler: sendAction)
                    .tint(.element.brand)
                    .padding(.vertical, 10)
                
                Button {
                    sendAction()
                } label: {
                    submitButtonImage
                        .symbolVariant(.fill)
                        .font(.element.body)
                        .foregroundColor(sendingDisabled ? .element.quaternaryContent : .global.white)
                        .background {
                            Circle()
                                .foregroundColor(sendingDisabled ? .clear : .element.brand)
                        }
                }
                .disabled(sendingDisabled)
                .animation(.linear(duration: 0.1), value: sendingDisabled)
                .keyboardShortcut(.return, modifiers: [.command])
                .padding([.vertical, .trailing], 6)
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
        // Explicitly disable all animations to fix weirdness with the header immediately
        // appearing whilst the text field and keyboard are still animating up to it.
        .animation(.noAnimation, value: type)
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
                .accessibilityLabel(L10n.actionConfirm)
                .accessibilityHidden(!type.isEdit)
            Image(asset: Asset.Images.timelineComposerSendMessage)
                .resizable()
                .frame(width: sendButtonIconSize, height: sendButtonIconSize)
                .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 6))
                .opacity(type.isEdit ? 0 : 1)
                .accessibilityLabel(L10n.actionSend)
                .accessibilityHidden(type.isEdit)
        }
    }
    
    private var borderRadius: CGFloat {
        switch type {
        case .default:
            return isMultiline ? 20 : 28
        case .reply, .edit:
            return 20
        }
    }
}

private struct MessageComposerReplyHeader: View {
    let displayName: String
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Label(L10n.commonReplyingTo(displayName), systemImage: "arrowshape.turn.up.left")
                .labelStyle(MessageComposerHeaderLabelStyle())
            Spacer()
            Button(action: action) {
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
            Label(L10n.commonEditing, systemImage: "pencil.line")
                .labelStyle(MessageComposerHeaderLabelStyle())
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.element.caption2.weight(.medium))
                    .foregroundColor(.element.secondaryContent)
                    .padding(12.0)
            }
        }
    }
}

private struct MessageComposerHeaderLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            configuration.icon
            configuration.title
        }
        .font(.element.caption1)
        .foregroundColor(.element.secondaryContent)
        .lineLimit(1)
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
        .padding(.horizontal)
    }
}
