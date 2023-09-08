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
import WysiwygComposer

typealias EnterKeyHandler = () -> Void
typealias PasteHandler = (NSItemProvider) -> Void

struct MessageComposer: View {
    @Binding var plainText: String
    let composerView: WysiwygComposerView
    let mode: RoomScreenComposerMode
    let showResizeHandle: Bool
    @Binding var isExpanded: Bool
    let sendAction: EnterKeyHandler
    let pasteAction: PasteHandler
    let replyCancellationAction: () -> Void
    let editCancellationAction: () -> Void
    let onAppearAction: () -> Void
    @FocusState private var focused: Bool

    @State private var isMultiline = false
    @State private var composerTranslation: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if showResizeHandle {
                resizeHandle
            }

            mainContent
                .padding(.horizontal, 12.0)
                .clipShape(RoundedRectangle(cornerRadius: borderRadius))
                .background {
                    let roundedRectangle = RoundedRectangle(cornerRadius: borderRadius)
                    ZStack {
                        roundedRectangle
                            .fill(Color.compound.bgSubtleSecondary)
                        roundedRectangle
                            .stroke(Color.compound._borderTextFieldFocused, lineWidth: 1)
                            .opacity(focused ? 1 : 0)
                    }
                }
                // Explicitly disable all animations to fix weirdness with the header immediately
                // appearing whilst the text field and keyboard are still animating up to it.
                .animation(.noAnimation, value: mode)
        }
        .gesture(dragGesture)
    }

    // MARK: - Private

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: -6) {
            header
            HStack(alignment: .bottom) {
                if ServiceLocator.shared.settings.richTextEditorEnabled {
                    composerView
                        .frame(minHeight: composerHeight, alignment: .top)
                        .tint(.compound.iconAccentTertiary)
                        .padding(.vertical, 10)
                        .focused($focused)
                        .onAppear {
                            onAppearAction()
                        }
                } else {
                    MessageComposerTextField(placeholder: L10n.richTextEditorComposerPlaceholder,
                                             text: $plainText,
                                             isMultiline: $isMultiline,
                                             maxHeight: 300,
                                             enterKeyHandler: sendAction,
                                             pasteHandler: pasteAction)
                        .tint(.compound.iconAccentTertiary)
                        .padding(.vertical, 10)
                        .focused($focused)
                }
            }
        }
    }

    private var composerHeight: CGFloat {
        let baseHeight = isExpanded ? ComposerConstant.maxHeight : ComposerConstant.minHeight
        return (baseHeight - composerTranslation).clamped(to: ComposerConstant.allowedHeightRange)
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
    
    private var borderRadius: CGFloat {
        switch mode {
        case .default:
            return isMultiline ? 20 : 28
        case .reply, .edit:
            return 20
        }
    }

    private var resizeHandle: some View {
        Capsule()
            .foregroundColor(.compound.iconTertiary)
            .frame(width: 36, height: 5)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                composerTranslation += value.translation.height
            }
            .onEnded { _ in
                withElementAnimation(.easeIn(duration: 0.3)) {
                    if composerTranslation > ComposerConstant.translationThreshold {
                        isExpanded = false
                    } else if composerTranslation < -ComposerConstant.translationThreshold {
                        isExpanded = true
                    }
                    composerTranslation = 0
                }
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
            .overlay(alignment: .topTrailing) {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.compound.bodySM.weight(.medium))
                        .foregroundColor(.compound.iconTertiary)
                        .padding(8.0)
                }
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal, -4.0)
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
                    .font(.compound.bodySM.weight(.medium))
                    .foregroundColor(.compound.iconTertiary)
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 14))
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

    static func messageComposer(_ content: String = "",
                                sendingDisabled: Bool = false,
                                mode: RoomScreenComposerMode = .default) -> MessageComposer {
        let viewModel = WysiwygComposerViewModel(minHeight: 22,
                                                 maxExpandedHeight: 250)
        viewModel.setMarkdownContent(content)

        let composerView = WysiwygComposerView(placeholder: L10n.richTextEditorComposerPlaceholder,
                                               viewModel: viewModel,
                                               itemProviderHelper: nil,
                                               keyCommandHandler: nil,
                                               pasteHandler: nil)

        return MessageComposer(plainText: .constant(content),
                               composerView: composerView,
                               mode: mode,
                               showResizeHandle: false,
                               isExpanded: .constant(false),
                               sendAction: { },
                               pasteAction: { _ in },
                               replyCancellationAction: { },
                               editCancellationAction: { },
                               onAppearAction: { viewModel.setup() })
    }

    static var previews: some View {
        VStack {
            messageComposer(sendingDisabled: true)

            messageComposer("Some message",
                            mode: .edit(originalItemId: .random))

            messageComposer(mode: .reply(itemID: .random,
                                         replyDetails: .loaded(sender: .init(id: "Kirk"),
                                                               contentType: .text(.init(body: "Text: Where the wild things are")))))
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
                    messageComposer(mode: .reply(itemID: .random,
                                                 replyDetails: replyDetails))
                }
            }
        }
        .padding(.horizontal)
        .environmentObject(viewModel.context)
        .previewDisplayName("Replying")
    }
}
