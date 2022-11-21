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
        let rect = RoundedRectangle(cornerRadius: borderRadius)
        VStack(alignment: .leading, spacing: 4.0) {
            header
            HStack(alignment: .center) {
                MessageComposerTextField(placeholder: ElementL10n.roomMessagePlaceholder,
                                         text: $text,
                                         focused: $focused,
                                         maxHeight: 300,
                                         onEnterKeyHandler: {
                                             sendAction()
                                         })
                
                Button {
                    sendAction()
                } label: {
                    Image(systemName: "paperplane")
                        .font(.element.title3)
                        .foregroundColor(sendingDisabled ? .element.tempActionBackground : .element.tempActionForeground)
                        .padding(8.0)
                        .background(
                            Circle()
                                .foregroundColor(sendingDisabled ? .clear : .element.tempActionBackground)
                        )
                }
                .disabled(sendingDisabled)
                .animation(.elementDefault, value: sendingDisabled)
                .keyboardShortcut(.return, modifiers: [.command])
                .padding(4.0)
            }
        }
        .padding(.leading, 12.0)
        .background(.thinMaterial)
        .clipShape(rect)
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
            Label(ElementL10n.roomTimelineReplyingTo(displayName), systemImage: "arrow.uturn.left")
                .font(.element.caption2)
                .foregroundColor(.element.secondaryContent)
                .lineLimit(1)
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: "x.circle")
                    .font(.element.callout)
                    .foregroundColor(.element.secondaryContent)
                    .padding(4.0)
            }
        }
    }
}

private struct MessageComposerEditHeader: View {
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Label(ElementL10n.roomTimelineEditing, systemImage: "pencil")
                .font(.element.caption2)
                .foregroundColor(.element.secondaryContent)
                .lineLimit(1)
            Spacer()
            Button {
                action()
            } label: {
                Image(systemName: "x.circle")
                    .font(.element.callout)
                    .foregroundColor(.element.secondaryContent)
                    .padding(4.0)
            }
        }
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
    }
}
