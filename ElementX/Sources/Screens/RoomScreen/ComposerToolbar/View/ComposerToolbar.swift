//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import MatrixRustSDK
import SwiftUI
import WysiwygComposer

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
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
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .padding(.bottom, context.composerFormattingEnabled ? 8 : 12)
        .background {
            if context.composerFormattingEnabled {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 0.5)
                    .ignoresSafeArea()
            }
        }
        .readFrame($frame)
        .safeAreaInset(edge: .top) {
            if !context.viewState.isRoomEncrypted {
                Label {
                    Text(L10n.commonNotEncrypted)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                } icon: {
                    CompoundIcon(\.lockOff, size: .xSmall, relativeTo: .compound.bodyMD)
                        .foregroundStyle(.compound.iconInfoPrimary)
                }
                .padding(4.0)
            }
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if verticalSizeClass != .compact, !context.composerExpanded {
                    suggestionView
                        .offset(y: -frame.height)
                }
            }
        }
        .disabled(!context.viewState.canSend)
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
                        .scaledFrame(size: 36, relativeTo: .compound.headingLG)
                        .scaledPadding(.vertical, 3, relativeTo: .compound.headingLG)
                } else if context.viewState.showSendButton {
                    sendButton
                        .scaledPadding(.vertical, 3, relativeTo: .compound.headingLG)
                } else {
                    voiceMessageRecordingButton(mode: context.viewState.isVoiceMessageModeActivated ? .recording : .idle)
                        .scaledPadding(.vertical, 3, relativeTo: .compound.headingLG)
                }
            }
        }
        .animation(.linear(duration: 0.15), value: context.viewState.composerMode)
    }
    
    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 4) {
            closeRTEButton
            
            FormattingToolbar(formatItems: context.formatItems) { action in
                context.send(viewAction: .composerAction(action: action.composerAction))
            }
            .padding(.horizontal, 5)
            
            sendButton
        }
    }
    
    private var topBarLayout: some Layout {
        HStackLayout(alignment: .bottom, spacing: 12)
    }
    
    private var mainTopBarContent: some View {
        ZStack(alignment: .bottom) {
            topBarLayout {
                if !context.composerFormattingEnabled {
                    RoomAttachmentPicker(context: context)
                        .scaledPadding(.vertical, 6, relativeTo: .compound.headingLG)
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
            CompoundIcon(\.close, size: .small, relativeTo: .compound.headingLG)
        }
        .buttonStyle(ComposerToolbarButtonStyle())
        .accessibilityLabel(L10n.richTextEditorCloseFormattingOptions)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
    }
    
    private var sendButton: some View {
        Group {
            if context.viewState.composerMode.isEdit {
                Button(action: sendMessage) {
                    CompoundIcon(\.check, size: .medium, relativeTo: .compound.headingLG)
                        .foregroundColor(.white)
                        .scaledPadding(6, relativeTo: .compound.headingLG)
                        .background(.compound.bgAccentRest, in: .circle)
                        .compositingGroup()
                }
                .accessibilityLabel(L10n.actionConfirm)
            } else {
                SendButton(action: sendMessage)
                    .accessibilityLabel(L10n.actionSend)
            }
        }
        .disabled(context.viewState.sendButtonDisabled)
        .animation(.linear(duration: 0.1).disabledDuringTests(), value: context.viewState.sendButtonDisabled)
        .keyboardShortcut(.return, modifiers: [.command])
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.sendButton)
    }
    
    private var messageComposer: some View {
        MessageComposer(plainComposerText: $context.plainComposerText,
                        presendCallback: $context.presendCallback,
                        selectedRange: $context.selectedRange,
                        composerView: composerView,
                        mode: context.viewState.composerMode,
                        placeholder: placeholder,
                        composerFormattingEnabled: context.composerFormattingEnabled,
                        showResizeGrabber: context.composerFormattingEnabled,
                        isExpanded: $context.composerExpanded) {
            sendMessage()
        } editAction: {
            context.send(viewAction: .editLastMessage)
        } pasteAction: { providers in
            context.send(viewAction: .handlePasteOrDrop(providers: providers))
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
        .onDisappear {
            context.send(viewAction: .composerDisappeared)
        }
        .environmentObject(context)
        .focused($composerFocused)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.messageComposer)
        .onTapGesture {
            guard !composerFocused else { return }
            composerFocused = true
        }
        .onChange(of: context.composerFocused) { _, newValue in
            guard composerFocused != newValue else { return }
            
            composerFocused = newValue
        }
        .onChange(of: composerFocused) { _, newValue in
            context.composerFocused = newValue
        }
        .onChange(of: context.plainComposerText) {
            context.send(viewAction: .plainComposerTextChanged)
        }
        .onChange(of: context.composerFormattingEnabled) {
            context.send(viewAction: .didToggleFormattingOptions)
        }
        .onChange(of: context.selectedRange) {
            context.send(viewAction: .selectedTextChanged)
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
            return isThread ? L10n.actionReplyInThread : composerPlaceholder
        default:
            return composerPlaceholder
        }
    }
    
    private var composerPlaceholder: String {
        L10n.richTextEditorComposerPlaceholder
    }
    
    private var composerView: WysiwygComposerView {
        WysiwygComposerView(placeholder: placeholder,
                            placeholderColor: .compound.textSecondary,
                            viewModel: context.viewState.wysiwygViewModel,
                            itemProviderHelper: ItemProviderHelper(),
                            keyCommands: context.viewState.keyCommands) { provider in
            context.send(viewAction: .handlePasteOrDrop(providers: [provider]))
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
                    .scaledPadding(.vertical, 6, relativeTo: .compound.headingLG)
                VoiceMessageRecordingComposer(recorderState: state)
            }
        case .previewVoiceMessage(let state, let waveform, let isUploading):
            topBarLayout {
                voiceMessageTrashButton
                    .scaledPadding(.vertical, 6, relativeTo: .compound.headingLG)
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
                .scaledFrame(size: 30, relativeTo: .compound.headingLG)
        }
        .buttonStyle(.compound(.textLink))
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

struct ComposerToolbarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.compound.iconOnSolidPrimary)
            .scaledPadding(5, relativeTo: .compound.headingLG)
            .background(backgroundColor(isPressed: configuration.isPressed), in: .circle)
    }
    
    func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return .compound.bgActionPrimaryDisabled }
        return isPressed ? .compound.bgActionPrimaryPressed : .compound.bgActionPrimaryRest
    }
}

// MARK: - Previews

struct ComposerToolbar_Previews: PreviewProvider, TestablePreview {
    static let timelineViewModel = TimelineViewModel.mock
    
    static let viewModel = ComposerToolbarViewModel.mock()
    static let focusedViewModel = ComposerToolbarViewModel.mock(focused: true, message: "Hello, World!")
    static let editingViewModel = ComposerToolbarViewModel.mock(message: "Hello, Wrold!", mockMode: .editing)
    static let multiLineViewModel = ComposerToolbarViewModel.mock(message: "Hello, World! This is a loooong message that wraps onto multiple lines.")
    static let voiceMessageRecordingViewModel = ComposerToolbarViewModel.mock(mockMode: .recordVoiceMessage)
    static let voiceMessagePreviewViewModel = ComposerToolbarViewModel.mock(mockMode: .previewVoiceMessage(isUploading: false))
    static let voiceMessageUploadingViewModel = ComposerToolbarViewModel.mock(mockMode: .previewVoiceMessage(isUploading: true))
    static let replyLoadingViewModel = ComposerToolbarViewModel.mock(mockMode: .reply(isLoading: true))
    static let replyLoadedViewModel = ComposerToolbarViewModel.mock(mockMode: .reply(isLoading: false))
    static let suggestionsViewModel = ComposerToolbarViewModel.mock(hasSuggestions: true)
    static let disabledViewModel = ComposerToolbarViewModel.mock(canSend: false)
    
    static var previews: some View {
        VStack(spacing: 8) {
            ComposerToolbar(context: viewModel.context)
            ComposerToolbar(context: focusedViewModel.context)
            ComposerToolbar(context: editingViewModel.context)
            ComposerToolbar(context: multiLineViewModel.context)
                .padding(.bottom)
            
            ComposerToolbar(context: voiceMessageRecordingViewModel.context)
            ComposerToolbar(context: voiceMessagePreviewViewModel.context)
            ComposerToolbar(context: voiceMessageUploadingViewModel.context)
                .padding(.bottom)
            
            ComposerToolbar(context: disabledViewModel.context)
        }
        
        // Putting them in a VStack allows the completion suggestion preview to work properly in tests
        VStack(spacing: 8) {
            ComposerToolbar(context: suggestionsViewModel.context)
        }
        .previewDisplayName("With Suggestions")
        
        VStack(spacing: 8) {
            ComposerToolbar(context: replyLoadingViewModel.context)
            ComposerToolbar(context: replyLoadedViewModel.context)
        }
        .environmentObject(timelineViewModel.context)
        .previewDisplayName("Reply")
    }
}
