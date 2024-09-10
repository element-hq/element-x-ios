//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI
import WysiwygComposer

typealias GenericKeyHandler = (_ key: UIKeyboardHIDUsage) -> Void
typealias PasteHandler = (NSItemProvider) -> Void

struct MessageComposer: View {
    @Binding var plainComposerText: NSAttributedString
    @Binding var presendCallback: (() -> Void)?
    let composerView: WysiwygComposerView
    let mode: ComposerMode
    let composerFormattingEnabled: Bool
    let showResizeGrabber: Bool
    @Binding var isExpanded: Bool
    let sendAction: () -> Void
    let editAction: () -> Void
    let pasteAction: PasteHandler
    let cancellationAction: () -> Void
    let onAppearAction: () -> Void
    
    @State private var composerTranslation: CGFloat = 0
    private let composerShape = RoundedRectangle(cornerRadius: 21, style: .circular)
    
    var body: some View {
        VStack(spacing: 0) {
            if showResizeGrabber {
                resizeGrabber
            }
            
            mainContent
                .padding(.horizontal, 12.0)
                .clipShape(composerShape)
                .background {
                    ZStack {
                        composerShape
                            .fill(Color.compound.bgSubtleSecondary)
                        composerShape
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
    
    @State private var composerFrame = CGRect.zero
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: -6) {
            header
            
            if composerFormattingEnabled {
                Color.clear
                    .overlay(alignment: .top) {
                        composerView
                            .clipped()
                            .readFrame($composerFrame)
                    }
                    .frame(minHeight: ComposerConstant.minHeight, maxHeight: max(composerHeight, composerFrame.height),
                           alignment: .top)
                    .tint(.compound.iconAccentTertiary)
                    .padding(.vertical, 10)
                    .onAppear {
                        onAppearAction()
                    }
            } else {
                MessageComposerTextField(placeholder: L10n.richTextEditorComposerPlaceholder,
                                         text: $plainComposerText,
                                         presendCallback: $presendCallback,
                                         maxHeight: ComposerConstant.maxHeight,
                                         keyHandler: { handleKeyPress($0) },
                                         pasteHandler: pasteAction)
                    .tint(.compound.iconAccentTertiary)
                    .padding(.vertical, 10)
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
            MessageComposerReplyHeader(replyDetails: replyDetails, action: cancellationAction)
        case .edit:
            MessageComposerEditHeader(action: cancellationAction)
        case .recordVoiceMessage, .previewVoiceMessage, .default:
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
    
    private func handleKeyPress(_ key: UIKeyboardHIDUsage) {
        switch key {
        case .keyboardReturnOrEnter:
            sendAction()
        case .keyboardUpArrow:
            editAction()
        case .keyboardEscape:
            cancellationAction()
        default:
            break
        }
    }
}

private struct MessageComposerReplyHeader: View {
    let replyDetails: TimelineItemReplyDetails
    let action: () -> Void
    
    var body: some View {
        TimelineReplyView(placement: .composer, timelineItemReplyDetails: replyDetails)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(4.0)
            .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 13, style: .circular))
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
        HStack(alignment: .center, spacing: 8) {
            Label(L10n.commonEditing,
                  icon: \.editSolid,
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
    static let viewModel = TimelineViewModel.mock
    
    static let replyTypes: [TimelineItemReplyDetails] = [
        .loaded(sender: .init(id: "Dave"),
                eventID: "123",
                eventContent: .message(.audio(.init(body: "Audio: Ride the lightning", duration: 100, waveform: nil, source: nil, contentType: nil)))),
        .loaded(sender: .init(id: "James"),
                eventID: "123",
                eventContent: .message(.emote(.init(body: "Emote: James thinks he's the phantom lord")))),
        .loaded(sender: .init(id: "Robert"),
                eventID: "123",
                eventContent: .message(.file(.init(body: "File: Crash course in brain surgery.pdf", source: nil, thumbnailSource: nil, contentType: nil)))),
        .loaded(sender: .init(id: "Cliff"),
                eventID: "123",
                eventContent: .message(.image(.init(body: "Image: Pushead",
                                                    source: .init(url: .picturesDirectory, mimeType: nil),
                                                    thumbnailSource: .init(url: .picturesDirectory, mimeType: nil))))),
        .loaded(sender: .init(id: "Jason"),
                eventID: "123",
                eventContent: .message(.notice(.init(body: "Notice: Too far gone?")))),
        .loaded(sender: .init(id: "Kirk"),
                eventID: "123",
                eventContent: .message(.text(.init(body: "Text: Where the wild things are")))),
        .loaded(sender: .init(id: "Lars"),
                eventID: "123",
                eventContent: .message(.video(.init(body: "Video: Through the never",
                                                    duration: 100,
                                                    source: nil,
                                                    thumbnailSource: .init(url: .picturesDirectory, mimeType: nil))))),
        .loading(eventID: "")
    ]
    
    static func messageComposer(_ content: NSAttributedString = .init(string: ""),
                                mode: ComposerMode = .default) -> MessageComposer {
        let viewModel = WysiwygComposerViewModel(minHeight: 22,
                                                 maxExpandedHeight: 250)
        viewModel.setMarkdownContent(content.string)
        
        let composerView = WysiwygComposerView(placeholder: L10n.richTextEditorComposerPlaceholder,
                                               viewModel: viewModel,
                                               itemProviderHelper: nil,
                                               keyCommands: nil,
                                               pasteHandler: nil)
        
        return MessageComposer(plainComposerText: .constant(content),
                               presendCallback: .constant(nil),
                               composerView: composerView,
                               mode: mode,
                               composerFormattingEnabled: false,
                               showResizeGrabber: false,
                               isExpanded: .constant(false),
                               sendAction: { },
                               editAction: { },
                               pasteAction: { _ in },
                               cancellationAction: { },
                               onAppearAction: { viewModel.setup() })
    }
    
    static var previews: some View {
        VStack(spacing: 8) {
            messageComposer()
            
            messageComposer(.init(string: "Some message"),
                            mode: .edit(originalItemId: .random))
            
            messageComposer(mode: .reply(itemID: .random,
                                         replyDetails: .loaded(sender: .init(id: "Kirk"),
                                                               eventID: "123",
                                                               eventContent: .message(.text(.init(body: "Text: Where the wild things are")))),
                                         isThread: false))
        }
        .padding(.horizontal)
        
        ScrollView {
            VStack(spacing: 8) {
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
            VStack(spacing: 8) {
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
