//
// Copyright 2023 New Vector Ltd
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

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    let wysiwygViewModel: WysiwygComposerViewModel
    let keyCommandHandler: KeyCommandHandler
    
    @FocusState private var composerFocused: Bool
    @ScaledMetric private var sendButtonIconSize = 16
    @ScaledMetric(relativeTo: .title) private var spinnerSize = 44
    @ScaledMetric(relativeTo: .title) private var closeRTEButtonSize = 30
    @State private var frame: CGRect = .zero
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        VStack(spacing: 8) {
            topBar
            
            if context.composerActionsEnabled {
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
        CompletionSuggestionView(imageProvider: context.imageProvider,
                                 items: context.viewState.suggestions,
                                 showBackgroundShadow: !context.composerExpanded) { suggestion in
            context.send(viewAction: .selectedSuggestion(suggestion))
        }
    }
    
    private var topBar: some View {
        topBarLayout {
            mainTopBarContent
            
            if !context.composerActionsEnabled {
                if context.viewState.isUploading {
                    ProgressView()
                        .frame(width: spinnerSize, height: spinnerSize)
                        .padding(.leading, 3)
                } else if context.viewState.showSendButton {
                    sendButton
                        .padding(.leading, 3)
                } else {
                    voiceMessageRecordingButton
                        .padding(.leading, 4)
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
                if !context.composerActionsEnabled {
                    RoomAttachmentPicker(context: context)
                }
                messageComposer
                    .environmentObject(context)
                    .onTapGesture {
                        guard !composerFocused else { return }
                        composerFocused = true
                    }
                    .padding(.leading, context.composerActionsEnabled ? 7 : 0)
                    .padding(.trailing, context.composerActionsEnabled ? 4 : 0)
            }
            .opacity(context.viewState.isVoiceMessageModeActivated ? 0 : 1)
            
            if context.viewState.isVoiceMessageModeActivated {
                voiceMessageContent
            }
        }
    }
    
    private var closeRTEButton: some View {
        Button {
            context.composerActionsEnabled = false
            context.composerExpanded = false
        } label: {
            Image(Asset.Images.closeRte.name)
                .resizable()
                .scaledToFit()
                .frame(width: closeRTEButtonSize, height: closeRTEButtonSize)
                .padding(7)
        }
        .accessibilityLabel(L10n.actionClose)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
    }
    
    private var sendButton: some View {
        Button {
            context.send(viewAction: .sendMessage)
        } label: {
            submitButtonImage
                .symbolVariant(.fill)
                .font(.compound.bodyLG)
                .foregroundColor(context.viewState.sendButtonDisabled ? .compound.iconDisabled : .white)
                .background {
                    Circle()
                        .foregroundColor(context.viewState.sendButtonDisabled ? .clear : .compound.iconAccentTertiary)
                }
                .padding(4)
        }
        .disabled(context.viewState.sendButtonDisabled)
        .animation(.linear(duration: 0.1).disabledDuringTests(), value: context.viewState.sendButtonDisabled)
        .keyboardShortcut(.return, modifiers: [.command])
    }
    
    private var messageComposer: some View {
        MessageComposer(composerView: composerView,
                        mode: context.viewState.composerMode,
                        showResizeGrabber: context.viewState.bindings.composerActionsEnabled,
                        isExpanded: $context.composerExpanded) {
            context.send(viewAction: .sendMessage)
        } pasteAction: { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        } replyCancellationAction: {
            context.send(viewAction: .cancelReply)
        } editCancellationAction: {
            context.send(viewAction: .cancelEdit)
        } onAppearAction: {
            context.send(viewAction: .composerAppeared)
        }
        .focused($composerFocused)
        .onChange(of: context.composerFocused) { newValue in
            guard composerFocused != newValue else { return }
            
            composerFocused = newValue
        }
        .onChange(of: composerFocused) { newValue in
            context.composerFocused = newValue
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
                            keyCommandHandler: keyCommandHandler) { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        }
    }
    
    private var submitButtonImage: some View {
        // ZStack with opacity so the button size is consistent.
        ZStack {
            CompoundIcon(\.check)
                .opacity(context.viewState.composerMode.isEdit ? 1 : 0)
                .accessibilityLabel(L10n.actionConfirm)
                .accessibilityHidden(!context.viewState.composerMode.isEdit)
            Image(asset: Asset.Images.sendMessage)
                .resizable()
                .frame(width: sendButtonIconSize, height: sendButtonIconSize)
                .padding(EdgeInsets(top: 10, leading: 11, bottom: 10, trailing: 9))
                .opacity(context.viewState.composerMode.isEdit ? 0 : 1)
                .accessibilityLabel(L10n.actionSend)
                .accessibilityHidden(context.viewState.composerMode.isEdit)
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
            VoiceMessageRecordingComposer(recorderState: state)
                .padding(.leading, 12)
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
    
    private var voiceMessageRecordingButton: some View {
        VoiceMessageRecordingButton {
            context.send(viewAction: .startVoiceMessageRecording)
        } stopRecording: { minimumRecordTimeReached in
            if minimumRecordTimeReached {
                context.send(viewAction: .stopVoiceMessageRecording)
            } else {
                context.send(viewAction: .cancelVoiceMessageRecording)
            }
        }
        .padding(4)
    }
    
    private var voiceMessageTrashButton: some View {
        Button(role: .destructive) {
            context.send(viewAction: .deleteVoiceMessageRecording)
        } label: {
            CompoundIcon(\.delete)
                .padding(EdgeInsets(top: 10, leading: 11, bottom: 10, trailing: 11))
        }
        .buttonStyle(.compound(.plain))
        .accessibilityLabel(L10n.a11yDelete)
    }
    
    private func voiceMessagePreviewComposer(audioPlayerState: AudioPlayerState, waveform: WaveformSource) -> some View {
        VoiceMessagePreviewComposer(playerState: audioPlayerState, waveform: waveform) {
            context.send(viewAction: .startVoiceMessagePlayback)
        } onPause: {
            context.send(viewAction: .pauseVoiceMessagePlayback)
        } onSeek: { progress in
            context.send(viewAction: .seekVoiceMessagePlayback(progress: progress))
        } onScrubbing: { isScrubbing in
            context.send(viewAction: .scrubVoiceMessagePlayback(scrubbing: isScrubbing))
        }
    }
}

struct ComposerToolbar_Previews: PreviewProvider, TestablePreview {
    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                            completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init(suggestions: suggestions)),
                                                            mediaProvider: MockMediaProvider(),
                                                            appSettings: ServiceLocator.shared.settings,
                                                            mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
    static let suggestions: [SuggestionItem] = [.user(item: MentionSuggestionItem(id: "@user_mention_1:matrix.org", displayName: "User 1", avatarURL: nil)),
                                                .user(item: MentionSuggestionItem(id: "@user_mention_2:matrix.org", displayName: "User 2", avatarURL: URL.documentsDirectory))]
    
    static var previews: some View {
        ComposerToolbar.mock(focused: true)
        
        // Putting them is VStack allows the completion suggestion preview to work properly in tests
        VStack {
            // The mock functon can't be used in this context because it does not hold a reference to the view model, losing the combine subscriptions
            ComposerToolbar(context: composerViewModel.context,
                            wysiwygViewModel: wysiwygViewModel,
                            keyCommandHandler: { _ in false })
        }
        .previewDisplayName("With Suggestions")
        
        VStack {
            ComposerToolbar.textWithVoiceMessage(focused: false)
            ComposerToolbar.textWithVoiceMessage(focused: true)
            ComposerToolbar.voiceMessageRecordingMock(recording: true)
            ComposerToolbar.voiceMessagePreviewMock(recording: false, uploading: false)
        }
        .previewDisplayName("Voice Message")
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
                                                 appSettings: ServiceLocator.shared.settings,
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
            model.state.composerEmpty = focused
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
    
    static func textWithVoiceMessage(focused: Bool = true) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 appSettings: ServiceLocator.shared.settings,
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
            model.state.composerEmpty = focused
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
    
    static func voiceMessageRecordingMock(recording: Bool) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 appSettings: ServiceLocator.shared.settings,
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
            model.state.composerMode = .recordVoiceMessage(state: AudioRecorderState())
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
    
    static func voiceMessagePreviewMock(recording: Bool, uploading: Bool) -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        let waveformData: [Float] = Array(repeating: 1.0, count: 1000)
        var composerViewModel: ComposerToolbarViewModel {
            let model = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                 completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                 mediaProvider: MockMediaProvider(),
                                                 appSettings: ServiceLocator.shared.settings,
                                                 mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
            model.state.composerMode = .previewVoiceMessage(state: AudioPlayerState(id: .recorderPreview, duration: 10.0), waveform: .data(waveformData), isUploading: uploading)
            return model
        }
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
}
