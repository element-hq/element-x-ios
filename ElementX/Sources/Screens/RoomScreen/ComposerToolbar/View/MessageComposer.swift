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
            
            composerTextField
                .messageComposerStyle(header: header)
                // Explicitly disable all animations to fix weirdness with the header immediately
                // appearing whilst the text field and keyboard are still animating up to it.
                .animation(.noAnimation, value: mode)
        }
        .gesture(showResizeGrabber ? dragGesture : nil)
    }
    
    // MARK: - Private
    
    @State private var composerFrame = CGRect.zero
    
    @ViewBuilder
    private var composerTextField: some View {
        if composerFormattingEnabled {
            Color.clear
                .overlay(alignment: .top) {
                    composerView
                        .clipped()
                        .readFrame($composerFrame)
                }
                .frame(minHeight: ComposerConstant.minHeight, maxHeight: max(composerHeight, composerFrame.height),
                       alignment: .top)
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
        case .edit(_, let editType):
            MessageComposerEditHeader(editType: editType, action: cancellationAction)
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
    let editType: ComposerMode.EditType
    let action: () -> Void
    
    private var title: String {
        switch editType {
        case .default: L10n.commonEditing
        case .addCaption: L10n.commonAddingCaption
        case .editCaption: L10n.commonEditingCaption
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Label(title, icon: \.editSolid, iconSize: .xSmall, relativeTo: .compound.bodySMSemibold)
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

// MARK: - Style

extension View {
    func messageComposerStyle(header: some View = EmptyView()) -> some View {
        modifier(MessageComposerStyleModifier(header: header))
    }
}

private struct MessageComposerStyleModifier<Header: View>: ViewModifier {
    private let composerShape = RoundedRectangle(cornerRadius: 21, style: .circular)
    
    let header: Header
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: -6) {
            header
            
            content
                .tint(.compound.iconAccentTertiary)
                .padding(.vertical, 10)
        }
        .padding(.horizontal, 12.0)
        .clipShape(composerShape)
        .background {
            ZStack {
                composerShape
                    .fill(Color.compound.bgSubtleSecondary)
                composerShape
                    .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Previews

struct MessageComposer_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static let replyTypes: [TimelineItemReplyDetails] = [
        .loaded(sender: .init(id: "Dave"),
                eventID: "123",
                eventContent: .message(.audio(.init(filename: "lightning.mp3",
                                                    caption: "Audio: Ride the lightning",
                                                    duration: 100,
                                                    waveform: nil,
                                                    source: nil,
                                                    fileSize: nil,
                                                    contentType: nil)))),
        .loaded(sender: .init(id: "James"),
                eventID: "123",
                eventContent: .message(.emote(.init(body: "Emote: James thinks he's the phantom lord")))),
        .loaded(sender: .init(id: "Robert"),
                eventID: "123",
                eventContent: .message(.file(.init(filename: "brain-surgery.pdf",
                                                   caption: "File: Crash course in brain surgery",
                                                   source: nil,
                                                   fileSize: nil,
                                                   thumbnailSource: nil,
                                                   contentType: nil)))),
        .loaded(sender: .init(id: "Cliff"),
                eventID: "123",
                eventContent: .message(.image(.init(filename: "head.png",
                                                    caption: "Image: Pushead",
                                                    imageInfo: .mockImage,
                                                    thumbnailInfo: .mockThumbnail)))),
        .loaded(sender: .init(id: "Jason"),
                eventID: "123",
                eventContent: .message(.notice(.init(body: "Notice: Too far gone?")))),
        .loaded(sender: .init(id: "Kirk"),
                eventID: "123",
                eventContent: .message(.text(.init(body: "Text: Where the wild things are")))),
        .loaded(sender: .init(id: "Lars"),
                eventID: "123",
                eventContent: .message(.video(.init(filename: "never.mov",
                                                    caption: "Video: Through the never",
                                                    videoInfo: .mockVideo,
                                                    thumbnailInfo: .mockVideoThumbnail)))),
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
                            mode: .edit(originalEventOrTransactionID: .eventId(eventId: UUID().uuidString), type: .default))
            
            messageComposer(mode: .reply(eventID: UUID().uuidString,
                                         replyDetails: .loaded(sender: .init(id: "Kirk"),
                                                               eventID: "123",
                                                               eventContent: .message(.text(.init(body: "Text: Where the wild things are")))),
                                         isThread: false))
            
            Color.clear.frame(height: 20)
            
            messageComposer(.init(string: "Some new caption"),
                            mode: .edit(originalEventOrTransactionID: .eventId(eventId: UUID().uuidString), type: .addCaption))
            messageComposer(.init(string: "Some updated caption"),
                            mode: .edit(originalEventOrTransactionID: .eventId(eventId: UUID().uuidString), type: .editCaption))
        }
        .padding(.horizontal)
        
        ScrollView {
            VStack(spacing: 8) {
                ForEach(replyTypes, id: \.self) { replyDetails in
                    messageComposer(mode: .reply(eventID: UUID().uuidString,
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
                    messageComposer(mode: .reply(eventID: UUID().uuidString,
                                                 replyDetails: replyDetails, isThread: true))
                }
            }
        }
        .padding(.horizontal)
        .environmentObject(viewModel.context)
        .previewDisplayName("Replying in thread")
    }
}
