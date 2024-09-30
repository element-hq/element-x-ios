//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI
import WysiwygComposer

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    
    // Needs to be observable or the placeholder and the dictation state are not managed correctly.
    @ObservedObject var wysiwygViewModel: WysiwygComposerViewModel
    
    let keyCommands: [WysiwygKeyCommand]
    
    @FocusState private var composerFocused: Bool
    @State private var frame: CGRect = .zero
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        VStack(spacing: 8) {
            topBar
            
            if context.composerFormattingEnabled {
                if verticalSizeClass != .compact,
                   context.composerExpanded {
                    suggestionView
                        .padding(.leading, -5)
                        .padding(.trailing, -8)
                }
                bottomBar
            }
        }
        .padding(.leading, 5)
        .padding(.trailing, 8)
        .readFrame($frame)
        .overlay(alignment: .bottom) {
            if verticalSizeClass != .compact, !context.composerExpanded {
                suggestionView
                    .offset(y: -frame.height)
            }
        }
        .alert(item: $context.alertInfo)
    }
    
    private var suggestionView: some View {
        CompletionSuggestionView(mediaProvider: context.mediaProvider,
                                 items: context.viewState.suggestions,
                                 showBackgroundShadow: !context.composerExpanded) { suggestion in
            context.send(viewAction: .selectedSuggestion(suggestion))
        }
    }
    
    private var topBar: some View {
        topBarLayout {
            mainTopBarContent
            
            if !context.composerFormattingEnabled {
                if context.viewState.isUploading {
                    ProgressView()
                        .scaledFrame(size: 44, relativeTo: .title)
                        .padding(.leading, 3)
                } else if context.viewState.showSendButton {
                    sendButton
                        .padding(.leading, 3)
                } else {
                    voiceMessageRecordingButton(mode: context.viewState.isVoiceMessageModeActivated ? .recording : .idle)
                        .padding(.leading, 3)
                }
            }
        }
        .animation(.linear(duration: 0.15), value: context.viewState.composerMode)
    }
    
    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 9) {
            closeRTEButton
            
            FormattingToolbar(formatItems: context.formatItems) { action in
                context.send(viewAction: .composerAction(action: action.composerAction))
            }
            
            sendButton
                .padding(.leading, 7)
        }
    }
    
    private var topBarLayout: some Layout {
        HStackLayout(alignment: .bottom, spacing: 5)
    }
    
    @ViewBuilder
    private var mainTopBarContent: some View {
        ZStack(alignment: .bottom) {
            topBarLayout {
                if !context.composerFormattingEnabled {
                    RoomAttachmentPicker(context: context)
                }
                messageComposer
            }
            .opacity(context.viewState.isVoiceMessageModeActivated ? 0 : 1)
            
            if context.viewState.isVoiceMessageModeActivated {
                voiceMessageContent
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var closeRTEButton: some View {
        Button {
            context.composerFormattingEnabled = false
            context.composerExpanded = false
        } label: {
            Image(Asset.Images.closeRte.name)
                .resizable()
                .scaledToFit()
                .scaledFrame(size: 30, relativeTo: .title)
                .scaledPadding(7, relativeTo: .title)
        }
        .accessibilityLabel(L10n.actionClose)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
    }
    
    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            CompoundIcon(context.viewState.composerMode.isEdit ? \.check : \.sendSolid)
                .scaledPadding(6, relativeTo: .title)
                .accessibilityLabel(context.viewState.composerMode.isEdit ? L10n.actionConfirm : L10n.actionSend)
                .foregroundColor(context.viewState.sendButtonDisabled ? .compound.iconDisabled : .white)
                .background {
                    Circle()
                        .foregroundColor(context.viewState.sendButtonDisabled ? .clear : .compound.iconAccentTertiary)
                }
                .scaledPadding(4, relativeTo: .title)
        }
        .disabled(context.viewState.sendButtonDisabled)
        .animation(.linear(duration: 0.1).disabledDuringTests(), value: context.viewState.sendButtonDisabled)
        .keyboardShortcut(.return, modifiers: [.command])
    }
    
    private var messageComposer: some View {
        MessageComposer(plainComposerText: $context.plainComposerText,
                        presendCallback: $context.presendCallback,
                        composerView: composerView,
                        mode: context.viewState.composerMode,
                        composerFormattingEnabled: context.composerFormattingEnabled,
                        showResizeGrabber: context.composerFormattingEnabled,
                        isExpanded: $context.composerExpanded) {
            sendMessage()
        } editAction: {
            context.send(viewAction: .editLastMessage)
        } pasteAction: { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        } cancellationAction: {
            switch context.viewState.composerMode {
            case .edit:
                context.send(viewAction: .cancelEdit)
            case .reply:
                context.send(viewAction: .cancelReply)
            default:
                break
            }
        } onAppearAction: {
            context.send(viewAction: .composerAppeared)
        }
        .environmentObject(context)
        .focused($composerFocused)
        .padding(.leading, context.composerFormattingEnabled ? 7 : 0)
        .padding(.trailing, context.composerFormattingEnabled ? 4 : 0)
        .onTapGesture {
            guard !composerFocused else { return }
            composerFocused = true
        }
        .onChange(of: context.composerFocused) { newValue in
            guard composerFocused != newValue else { return }
            
            composerFocused = newValue
        }
        .onChange(of: composerFocused) { newValue in
            context.composerFocused = newValue
        }
        .onChange(of: context.plainComposerText) { _ in
            context.send(viewAction: .plainComposerTextChanged)
        }
        .onChange(of: context.composerFormattingEnabled) { _ in
            context.send(viewAction: .didToggleFormattingOptions)
        }
        .onAppear {
            composerFocused = context.composerFocused
        }
    }
    
    private func sendMessage() {
        // Allow the inner TextField do apply any final processing before
        // sending e.g. accepting current autocorrection.
        // Fixes https://github.com/element-hq/element-x-ios/issues/3216
        context.presendCallback?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.send(viewAction: .sendMessage)
        }
    }
    
    private var placeholder: String {
        switch context.viewState.composerMode {
        case .reply(_, _, let isThread):
            return isThread ? L10n.actionReplyInThread : L10n.richTextEditorComposerPlaceholder
        default:
            return L10n.richTextEditorComposerPlaceholder
        }
    }
    
    private var composerView: WysiwygComposerView {
        WysiwygComposerView(placeholder: placeholder,
                            placeholderColor: .compound.textSecondary,
                            viewModel: wysiwygViewModel,
                            itemProviderHelper: ItemProviderHelper(),
                            keyCommands: keyCommands) { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        }
    }
    
    private class ItemProviderHelper: WysiwygItemProviderHelper {
        func isPasteSupported(for itemProvider: NSItemProvider) -> Bool {
            itemProvider.isSupportedForPasteOrDrop
        }
    }
    
    // MARK: - Voice message
    
    @ViewBuilder
    private var voiceMessageContent: some View {
        // Display the voice message composer above to keep the focus and keep the keyboard open if it's already open.
        switch context.viewState.composerMode {
        case .recordVoiceMessage(let state):
            topBarLayout {
                voiceMessageTrashButton
                VoiceMessageRecordingComposer(recorderState: state)
            }
        case .previewVoiceMessage(let state, let waveform, let isUploading):
            topBarLayout {
                voiceMessageTrashButton
                voiceMessagePreviewComposer(audioPlayerState: state, waveform: waveform)
            }
            .disabled(isUploading)
        default:
            EmptyView()
        }
    }
    
    private func voiceMessageRecordingButton(mode: VoiceMessageRecordingButtonMode) -> some View {
        VoiceMessageRecordingButton(mode: mode) {
            context.send(viewAction: .voiceMessage(.startRecording))
        } stopRecording: {
            context.send(viewAction: .voiceMessage(.stopRecording))
        }
    }
    
    private var voiceMessageTrashButton: some View {
        Button(role: .destructive) {
            context.send(viewAction: .voiceMessage(.deleteRecording))
        } label: {
            CompoundIcon(\.delete)
                .scaledToFit()
                .scaledFrame(size: 30, relativeTo: .title)
                .scaledPadding(7, relativeTo: .title)
        }
        .buttonStyle(.compound(.plain))
        .accessibilityLabel(L10n.a11yDelete)
    }
    
    private func voiceMessagePreviewComposer(audioPlayerState: AudioPlayerState, waveform: WaveformSource) -> some View {
        VoiceMessagePreviewComposer(playerState: audioPlayerState, waveform: waveform) {
            context.send(viewAction: .voiceMessage(.startPlayback))
        } onPause: {
            context.send(viewAction: .voiceMessage(.pausePlayback))
        } onSeek: { progress in
            context.send(viewAction: .voiceMessage(.seekPlayback(progress: progress)))
        } onScrubbing: { isScrubbing in
            context.send(viewAction: .voiceMessage(.scrubPlayback(scrubbing: isScrubbing)))
        }
    }
}

struct ComposerToolbar_Previews: PreviewProvider, TestablePreview {
    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                            completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init(suggestions: suggestions)),
                                                            mediaProvider: MockMediaProvider(),
                                                            mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                            analyticsService: ServiceLocator.shared.analytics,
                                                            composerDraftService: ComposerDraftServiceMock())
    static let suggestions: [SuggestionItem] = [.user(item: MentionSuggestionItem(id: "@user_mention_1:matrix.org", displayName: "User 1", avatarURL: nil, range: .init())),
                                                .user(item: MentionSuggestionItem(id: "@user_mention_2:matrix.org", displayName: "User 2", avatarURL: URL.documentsDirectory, range: .init()))]
    
    static var previews: some View {
        ComposerToolbar.mock(focused: true)
        
        // Putting them is VStack allows the completion suggestion preview to work properly in tests
        VStack(spacing: 8) {
            // The mock functon can't be used in this context because it does not hold a reference to the view model, losing the combine subscriptions
            ComposerToolbar(context: composerViewModel.context,
                            wysiwygViewModel: wysiwygViewModel,
                            keyCommands: [])
        }
        .previewDisplayName("With Suggestions")
        
        VStack(spacing: 8) {
            ComposerToolbar.textWithVoiceMessage(focused: false)
            ComposerToolbar.textWithVoiceMessage(focused: true)
            ComposerToolbar.voiceMessageRecordingMock()
            ComposerToolbar.voiceMessagePreviewMock(uploading: false)
        }
        .previewDisplayName("Voice Message")
        
        VStack(spacing: 8) {
            ComposerToolbar.replyLoadingPreviewMock(isLoading: true)
            ComposerToolbar.replyLoadingPreviewMock(isLoading: false)
        }
        .previewDisplayName("Reply")
    }
}

// MARK: - Mock

extension ComposerToolbar {
    static func mock(focused: Bool = true) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 composerDraftService: ComposerDraftServiceMock())
            model.state.composerEmpty = focused
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommands: [])
    }
    
    static func textWithVoiceMessage(focused: Bool = true) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 composerDraftService: ComposerDraftServiceMock())
            model.state.composerEmpty = focused
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommands: [])
    }
    
    static func voiceMessageRecordingMock() -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 composerDraftService: ComposerDraftServiceMock())
            model.state.composerMode = .recordVoiceMessage(state: AudioRecorderState())
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommands: [])
    }
    
    static func voiceMessagePreviewMock(uploading: Bool) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        let waveformData: [Float] = Array(repeating: 1.0, count: 1000)
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 composerDraftService: ComposerDraftServiceMock())
            model.state.composerMode = .previewVoiceMessage(state: AudioPlayerState(id: .recorderPreview,
                                                                                    title: L10n.commonVoiceMessage,
                                                                                    duration: 10.0),
                                                            waveform: .data(waveformData),
                                                            isUploading: uploading)
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommands: [])
    }
    
    static func replyLoadingPreviewMock(isLoading: Bool) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                 analyticsService: ServiceLocator.shared.analytics,
                                                 composerDraftService: ComposerDraftServiceMock())
            model.state.composerMode = isLoading ? .reply(itemID: .init(timelineID: ""),
                                                          replyDetails: .loading(eventID: ""),
                                                          isThread: false) :
                .reply(itemID: .init(timelineID: ""),
                       replyDetails: .loaded(sender: .init(id: "",
                                                           displayName: "Test"),
                                             eventID: "", eventContent: .message(.text(.init(body: "Hello World!")))), isThread: false)
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommands: [])
    }
}
