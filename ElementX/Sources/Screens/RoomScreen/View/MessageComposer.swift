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
    let mode: RoomScreenComposerMode
    
    let sendAction: EnterKeyHandler
    let pasteAction: PasteHandler
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
                                         enterKeyHandler: sendAction,
                                         pasteHandler: pasteAction)
                    .tint(.compound.iconAccentTertiary)
                    .padding(.vertical, 10)
                
                Button {
                    sendAction()
                } label: {
                    submitButtonImage
                        .symbolVariant(.fill)
                        .font(.compound.bodyLG)
                        .foregroundColor(sendingDisabled ? .element.quaternaryContent : .global.white)
                        .background {
                            Circle()
                                .foregroundColor(sendingDisabled ? .clear : .compound.iconAccentTertiary)
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
                    .fill(Color.compound.bgSubtleSecondary)
                roundedRectangle
                    .stroke(Color.element.quinaryContent, lineWidth: 1)
                    .opacity(focused ? 1 : 0)
            }
        }
        // Explicitly disable all animations to fix weirdness with the header immediately
        // appearing whilst the text field and keyboard are still animating up to it.
        .animation(.noAnimation, value: mode)
    }
    
    @ViewBuilder
    private var header: some View {
        switch mode {
        case .reply(_, let replyDetails):
            MessageComposerReplyHeader(replyDetails: replyDetails, action: replyCancellationAction)
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
                .opacity(mode.isEdit ? 1 : 0)
                .fontWeight(.medium)
                .accessibilityLabel(L10n.actionConfirm)
                .accessibilityHidden(!mode.isEdit)
            Image(asset: Asset.Images.timelineComposerSendMessage)
                .resizable()
                .frame(width: sendButtonIconSize, height: sendButtonIconSize)
                .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 6))
                .opacity(mode.isEdit ? 0 : 1)
                .accessibilityLabel(L10n.actionSend)
                .accessibilityHidden(mode.isEdit)
        }
    }
    
    private var borderRadius: CGFloat {
        switch mode {
        case .default:
            return isMultiline ? 20 : 28
        case .reply, .edit:
            return 20
        }
    }
}

private struct MessageComposerReplyHeader: View {
    let replyDetails: TimelineItemReplyDetails
    let action: () -> Void
    
    var body: some View {
        TimelineReplyView(placement: .composer, timelineItemReplyDetails: replyDetails)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4.0)
            .background(Color.compound.bgCanvasDefault)
            .cornerRadius(13.0)
            .padding([.trailing, .vertical], 8.0)
            .padding([.leading], -4.0)
            .overlay(alignment: .topTrailing) {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.element.tertiaryContent)
                        .padding(16.0)
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
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.element.tertiaryContent)
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
        .font(.compound.bodySM)
        .foregroundColor(.compound.textSecondary)
        .lineLimit(1)
    }
}

struct MessageComposer_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        VStack {
            MessageComposer(text: .constant(""),
                            focused: .constant(false),
                            sendingDisabled: true,
                            mode: .default,
                            sendAction: { },
                            pasteAction: { _ in },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is a short message."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            mode: .default,
                            sendAction: { },
                            pasteAction: { _ in },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is a very long message that will wrap to 2 lines on an iPhone 14."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            mode: .default,
                            sendAction: { },
                            pasteAction: { _ in },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("This is an even longer message that will wrap to 3 lines on an iPhone 14, just to see the difference it makes."),
                            focused: .constant(false),
                            sendingDisabled: false,
                            mode: .default,
                            sendAction: { },
                            pasteAction: { _ in },
                            replyCancellationAction: { },
                            editCancellationAction: { })
            
            MessageComposer(text: .constant("Some message"),
                            focused: .constant(false),
                            sendingDisabled: false,
                            mode: .edit(originalItemId: UUID().uuidString),
                            sendAction: { },
                            pasteAction: { _ in },
                            replyCancellationAction: { },
                            editCancellationAction: { })
        }
        .padding(.horizontal)
        
        ScrollView {
            VStack {
                let replyTypes: [TimelineItemReplyDetails] = [
                    .loaded(sender: .init(id: "Dave"), contentType: .audio(.init(body: "Audio: Ride the lightning", duration: 100, source: nil, contentType: nil))),
                    .loaded(sender: .init(id: "James"), contentType: .emote(.init(body: "Emote: James thinks he's the phantom lord"))),
                    .loaded(sender: .init(id: "Robert"), contentType: .file(.init(body: "File: Crash course in brain surgery.pdf", source: nil, thumbnailSource: nil, contentType: nil))),
                    .loaded(sender: .init(id: "Cliff"), contentType: .image(.init(body: "Image: Pushead",
                                                                                  source: .init(url: .picturesDirectory, mimeType: nil),
                                                                                  thumbnailSource: .init(url: .picturesDirectory, mimeType: nil)))),
                    .loaded(sender: .init(id: "Jason"), contentType: .notice(.init(body: "Notice: Too far gone?"))),
                    .loaded(sender: .init(id: "Kirk"), contentType: .text(.init(body: "Text: Where the wild things are"))),
                    .loaded(sender: .init(id: "Lars"), contentType: .video(.init(body: "Video: Through the never",
                                                                                 duration: 100,
                                                                                 source: nil,
                                                                                 thumbnailSource: .init(url: .picturesDirectory, mimeType: nil)))),
                    .loading(eventID: "")
                ]
                
                ForEach(replyTypes, id: \.self) { replyDetails in
                    MessageComposer(text: .constant(""),
                                    focused: .constant(false),
                                    sendingDisabled: false,
                                    mode: .reply(itemID: UUID().uuidString,
                                                 replyDetails: replyDetails),
                                    sendAction: { },
                                    pasteAction: { _ in },
                                    replyCancellationAction: { },
                                    editCancellationAction: { })
                }
            }
        }
        .padding(.horizontal)
        .environmentObject(viewModel.context)
        .previewDisplayName("Replying")
    }
}
