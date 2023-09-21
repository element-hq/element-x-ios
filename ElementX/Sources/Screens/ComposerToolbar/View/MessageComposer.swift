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

import Compound
import SwiftUI
import WysiwygComposer

typealias EnterKeyHandler = () -> Void
typealias PasteHandler = (NSItemProvider) -> Void

struct MessageComposer: View {
    let composerView: WysiwygComposerView
    let mode: RoomScreenComposerMode
    let showResizeGrabber: Bool
    @Binding var isExpanded: Bool
    let sendAction: EnterKeyHandler
    let pasteAction: PasteHandler
    let replyCancellationAction: () -> Void
    let editCancellationAction: () -> Void
    let onAppearAction: () -> Void
    @FocusState private var focused: Bool

    @State private var composerTranslation: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if showResizeGrabber {
                resizeGrabber
            }

            let borderRadius: CGFloat = 21
            mainContent
                .padding(.horizontal, 12.0)
                .clipShape(RoundedRectangle(cornerRadius: borderRadius))
                .background {
                    let roundedRectangle = RoundedRectangle(cornerRadius: borderRadius)
                    ZStack {
                        roundedRectangle
                            .fill(Color.compound.bgSubtleSecondary)
                        roundedRectangle
                            .stroke(Color.compound._borderTextFieldFocused, lineWidth: 0.5)
                    }
                }
                // Explicitly disable all animations to fix weirdness with the header immediately
                // appearing whilst the text field and keyboard are still animating up to it.
                .animation(.noAnimation, value: mode)
        }
        .gesture(showResizeGrabber ? dragGesture : nil)
    }

    // MARK: - Private

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: -6) {
            header

            composerView
                .frame(minHeight: composerHeight, alignment: .top)
                .tint(.compound.iconAccentTertiary)
                .padding(.vertical, 10)
                .focused($focused)
                .onAppear {
                    onAppearAction()
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
        case .reply(_, let replyDetails, _):
            MessageComposerReplyHeader(replyDetails: replyDetails, action: replyCancellationAction)
        case .edit:
            MessageComposerEditHeader(action: editCancellationAction)
        case .default:
            EmptyView()
        }
    }

    private var resizeGrabber: some View {
        Capsule()
            .foregroundColor(Asset.Colors.grabber.swiftUIColor)
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
                    CompoundIcon(\.close, size: .small, relativeTo: .compound.bodySMSemibold)
                        .foregroundColor(.compound.iconTertiary)
                        .padding(4.0)
                }
                .accessibilityLabel(L10n.actionClose)
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal, -4.0)
    }
}

private struct MessageComposerEditHeader: View {
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Label(L10n.commonEditing,
                  iconAsset: Asset.Images.editing,
                  iconSize: .xSmall,
                  relativeTo: .compound.bodySMSemibold)
                .labelStyle(MessageComposerHeaderLabelStyle())
            Spacer()
            Button(action: action) {
                CompoundIcon(\.close, size: .small, relativeTo: .compound.bodySMSemibold)
                    .foregroundColor(.compound.iconTertiary)
                    .padding([.leading, .vertical], 6.0)
            }
            .accessibilityLabel(L10n.actionClose)
        }
    }
}

private struct MessageComposerHeaderLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 4) {
            configuration.icon
            configuration.title
        }
        .font(.compound.bodySMSemibold)
        .foregroundColor(.compound.textSecondary)
        .lineLimit(1)
    }
}

struct MessageComposer_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel.mock
    
    static let replyTypes: [TimelineItemReplyDetails] = [
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

        return MessageComposer(composerView: composerView,
                               mode: mode,
                               showResizeGrabber: false,
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
                                                               contentType: .text(.init(body: "Text: Where the wild things are"))), isThread: false))
        }
        .padding(.horizontal)

        ScrollView {
            VStack {
                ForEach(replyTypes, id: \.self) { replyDetails in
                    messageComposer(mode: .reply(itemID: .random,
                                                 replyDetails: replyDetails, isThread: false))
                }
            }
        }
        .padding(.horizontal)
        .environmentObject(viewModel.context)
        .previewDisplayName("Replying")
        
        ScrollView {
            VStack {
                ForEach(replyTypes, id: \.self) { replyDetails in
                    messageComposer(mode: .reply(itemID: .random,
                                                 replyDetails: replyDetails, isThread: true))
                }
            }
        }
        .padding(.horizontal)
        .environmentObject(viewModel.context)
        .previewDisplayName("Replying in thread")
    }
}
