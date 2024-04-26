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

import Combine
import Foundation
import GameKit
import MatrixRustSDK
import SwiftUI
import WysiwygComposer

typealias ComposerToolbarViewModelType = StateStoreViewModel<ComposerToolbarViewState, ComposerToolbarViewAction>

final class ComposerToolbarViewModel: ComposerToolbarViewModelType, ComposerToolbarViewModelProtocol {
    private let wysiwygViewModel: WysiwygComposerViewModel
    private let completionSuggestionService: CompletionSuggestionServiceProtocol
    private let appSettings: AppSettings
    private var hasAppeard = false

    private let actionsSubject: PassthroughSubject<ComposerToolbarViewModelAction, Never> = .init()
    var actions: AnyPublisher<ComposerToolbarViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private struct WysiwygLinkData {
        let action: LinkAction
        let range: NSRange
        var url: String
        var text: String
    }

    private var currentLinkData: WysiwygLinkData?

    init(wysiwygViewModel: WysiwygComposerViewModel, completionSuggestionService: CompletionSuggestionServiceProtocol, mediaProvider: MediaProviderProtocol, appSettings: AppSettings, mentionDisplayHelper: MentionDisplayHelper) {
        self.wysiwygViewModel = wysiwygViewModel
        self.completionSuggestionService = completionSuggestionService
        self.appSettings = appSettings
        
        super.init(initialViewState: ComposerToolbarViewState(audioPlayerState: .init(id: .recorderPreview, duration: 0),
                                                              audioRecorderState: .init(),
                                                              bindings: .init()),
                   imageProvider: mediaProvider)

        context.$viewState
            .map(\.composerMode)
            .removeDuplicates()
            .sink { [weak self] in
                self?.wysiwygViewModel.shouldReplaceText = $0.isTextEditingEnabled
                self?.actionsSubject.send(.composerModeChanged(mode: $0))
            }
            .store(in: &cancellables)

        context.$viewState
            .map(\.bindings.composerFocused)
            .removeDuplicates()
            .sink { [weak self] in self?.actionsSubject.send(.composerFocusedChanged(isFocused: $0)) }
            .store(in: &cancellables)

        wysiwygViewModel.$isContentEmpty
            .removeDuplicates()
            .sink { [weak self] isEmpty in
                self?.state.composerEmpty = isEmpty
                self?.actionsSubject.send(.contentChanged(isEmpty: isEmpty))
            }
            .store(in: &cancellables)

        wysiwygViewModel.$actionStates
            .map { actions in
                FormatType
                    .allCases
                    .map { type in
                        FormatItem(type: type,
                                   state: actions[type.composerAction] ?? .disabled)
                    }
            }
            .weakAssign(to: \.state.bindings.formatItems, on: self)
            .store(in: &cancellables)
        
        wysiwygViewModel.$suggestionPattern
            .sink { [weak self] suggestionPattern in
                self?.completionSuggestionService.setSuggestionTrigger(suggestionPattern?.toElementPattern)
            }
            .store(in: &cancellables)
        
        completionSuggestionService.suggestionsPublisher
            .weakAssign(to: \.state.suggestions, on: self)
            .store(in: &cancellables)
        
        setupMentionsHandling(mentionDisplayHelper: mentionDisplayHelper)
        focusComposerIfHardwareKeyboardConnected()
    }
    
    // MARK: - Public

    override func process(viewAction: ComposerToolbarViewAction) {
        switch viewAction {
        case .composerAppeared:
            if !hasAppeard {
                hasAppeard = true
                wysiwygViewModel.setup()
            }
        case .sendMessage:
            guard !state.sendButtonDisabled else { return }
            
            switch state.composerMode {
            case .previewVoiceMessage:
                actionsSubject.send(.voiceMessage(.send))
            default:
                if ServiceLocator.shared.settings.richTextEditorEnabled {
                    let sendHTML = appSettings.richTextEditorEnabled
                    actionsSubject.send(.sendMessage(plain: wysiwygViewModel.content.markdown,
                                                     html: sendHTML ? wysiwygViewModel.content.html : nil,
                                                     mode: state.composerMode,
                                                     intentionalMentions: wysiwygViewModel.getMentionsState().toIntentionalMentions()))
                } else {
                    actionsSubject.send(.sendMessage(plain: context.plainComposerText.string, html: nil, mode: state.composerMode, intentionalMentions: .empty))
                }
            }
        case .cancelReply:
            set(mode: .default)
        case .cancelEdit:
            set(mode: .default)
            set(text: "")
        case .attach(let attachment):
            state.bindings.composerFocused = false
            actionsSubject.send(.attach(attachment))
        case .handlePasteOrDrop(let provider):
            actionsSubject.send(.handlePasteOrDrop(provider: provider))
        case .enableTextFormatting:
            state.bindings.composerActionsEnabled = true
            state.bindings.composerFocused = true
        case .composerAction(let action):
            if action == .link {
                createLinkAlert()
            } else {
                wysiwygViewModel.apply(action)
            }
        case .selectedSuggestion(let suggestion):
            handleSuggestion(suggestion)
        case .voiceMessage(let voiceMessageAction):
            processVoiceMessageAction(voiceMessageAction)
        case .plainComposerTextChanged:
            completionSuggestionService.processTextMessage(state.bindings.plainComposerText.string)
        }
    }

    func process(roomAction: RoomScreenComposerAction) {
        switch roomAction {
        case .setMode(mode: let mode):
            set(mode: mode)
        case .setText(text: let text):
            set(text: text)
        case .removeFocus:
            state.bindings.composerFocused = false
        case .clear:
            set(mode: .default)
            set(text: "")
        }
    }
    
    var keyCommands: [WysiwygKeyCommand] {
        [
            .enter { [weak self] in
                self?.process(viewAction: .sendMessage)
            }
        ]
    }

    // MARK: - Private
    
    private func processVoiceMessageAction(_ action: ComposerToolbarVoiceMessageAction) {
        switch action {
        case .startRecording:
            state.bindings.composerActionsEnabled = false
            actionsSubject.send(.voiceMessage(.startRecording))
        case .stopRecording:
            actionsSubject.send(.voiceMessage(.stopRecording))
        case .cancelRecording:
            actionsSubject.send(.voiceMessage(.cancelRecording))
        case .deleteRecording:
            actionsSubject.send(.voiceMessage(.deleteRecording))
        case .startPlayback:
            actionsSubject.send(.voiceMessage(.startPlayback))
        case .pausePlayback:
            actionsSubject.send(.voiceMessage(.pausePlayback))
        case .scrubPlayback(let scrubbing):
            actionsSubject.send(.voiceMessage(.scrubPlayback(scrubbing: scrubbing)))
        case .seekPlayback(let progress):
            actionsSubject.send(.voiceMessage(.seekPlayback(progress: progress)))
        case .send:
            break
        }
    }
    
    private func setupMentionsHandling(mentionDisplayHelper: MentionDisplayHelper) {
        wysiwygViewModel.mentionDisplayHelper = mentionDisplayHelper
        
        let attributedStringBuilder = AttributedStringBuilder(cacheKey: "Composer", mentionBuilder: MentionBuilder())
        
        wysiwygViewModel.mentionReplacer = ComposerMentionReplacer { urlString, string in
            let attributedString: NSMutableAttributedString
            // This is the all room mention special case
            if urlString == PillConstants.composerAtRoomURLString {
                attributedString = NSMutableAttributedString(string: string, attributes: [.MatrixAllUsersMention: true])
            } else {
                attributedString = NSMutableAttributedString(string: string, attributes: [.link: URL(string: urlString) as Any])
            }
            attributedStringBuilder.detectPermalinks(attributedString)
            
            // In RTE mentions don't need to be handled as links
            attributedString.removeAttribute(.link, range: NSRange(location: 0, length: attributedString.length))
            return attributedString
        }
    }
    
    private func handleSuggestion(_ suggestion: SuggestionItem) {
        switch suggestion {
        case let .user(item):
            guard let url = try? URL(string: matrixToUserPermalink(userId: item.id)) else {
                MXLog.error("Could not build user permalink")
                return
            }
            wysiwygViewModel.setMention(url: url.absoluteString, name: item.displayName ?? item.id, mentionType: .user)
        case .allUsers:
            wysiwygViewModel.setAtRoomMention()
        }
    }

    private func set(mode: RoomScreenComposerMode) {
        guard mode != state.composerMode else { return }

        state.composerMode = mode
        switch mode {
        case .default:
            break
        case .recordVoiceMessage(let audioRecorderState):
            state.audioRecorderState = audioRecorderState
        case .previewVoiceMessage(let audioPlayerState, _, _):
            state.audioPlayerState = audioPlayerState
        case .edit, .reply:
            // Focus composer when switching to reply/edit
            state.bindings.composerFocused = true
        }
    }

    private func set(text: String) {
        if ServiceLocator.shared.settings.richTextEditorEnabled {
            wysiwygViewModel.textView.flushPills()
            
            wysiwygViewModel.setHtmlContent(text)
        } else {
            state.bindings.plainComposerText = .init(string: text)
        }
    }

    private func createLinkAlert() {
        let linkAction = wysiwygViewModel.getLinkAction()
        currentLinkData = WysiwygLinkData(action: linkAction,
                                          range: wysiwygViewModel.attributedContent.selection,
                                          url: linkAction.url ?? "",
                                          text: "")

        let urlBinding: Binding<String> = .init { [weak self] in
            self?.currentLinkData?.url ?? ""
        } set: { [weak self] value in
            self?.currentLinkData?.url = value
        }

        let textBinding: Binding<String> = .init { [weak self] in
            self?.currentLinkData?.text ?? ""
        } set: { [weak self] value in
            self?.currentLinkData?.text = value
        }

        switch linkAction {
        case .createWithText:
            state.bindings.alertInfo = makeCreateWithTextAlertInfo(urlBinding: urlBinding, textBinding: textBinding)
        case .create:
            state.bindings.alertInfo = makeSetUrlAlertInfo(urlBinding: urlBinding, isEdit: false)
        case .edit:
            state.bindings.alertInfo = makeEditChoiceAlertInfo(urlBinding: urlBinding)
        case .disabled:
            break
        }
    }

    private func makeCreateWithTextAlertInfo(urlBinding: Binding<String>, textBinding: Binding<String>) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: L10n.richTextEditorCreateLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionCancel, action: {
                      self.restoreComposerSelectedRange()
                  }),
                  secondaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionSave, action: {
                      self.restoreComposerSelectedRange()
                      self.createLinkWithText()

                  }),
                  textFields: [AlertInfo<UUID>.AlertTextField(placeholder: L10n.commonText,
                                                              text: textBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: false),
                               AlertInfo<UUID>.AlertTextField(placeholder: L10n.richTextEditorUrlPlaceholder,
                                                              text: urlBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: true)])
    }

    private func makeSetUrlAlertInfo(urlBinding: Binding<String>, isEdit: Bool) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: isEdit ? L10n.richTextEditorEditLink : L10n.richTextEditorCreateLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionCancel, action: {
                      self.restoreComposerSelectedRange()
                  }),
                  secondaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionSave, action: {
                      self.restoreComposerSelectedRange()
                      self.setLink()

                  }),
                  textFields: [AlertInfo<UUID>.AlertTextField(placeholder: L10n.richTextEditorUrlPlaceholder,
                                                              text: urlBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: true)])
    }

    private func makeEditChoiceAlertInfo(urlBinding: Binding<String>) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: L10n.richTextEditorEditLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionRemove, role: .destructive, action: {
                      self.restoreComposerSelectedRange()
                      self.removeLinks()
                  }),
                  verticalButtons: [AlertInfo<UUID>.AlertButton(title: L10n.actionEdit, action: {
                      self.state.bindings.alertInfo = nil
                      DispatchQueue.main.async {
                          self.state.bindings.alertInfo = self.makeSetUrlAlertInfo(urlBinding: urlBinding, isEdit: true)
                      }
                  })])
    }

    private func restoreComposerSelectedRange() {
        guard let currentLinkData else { return }
        wysiwygViewModel.select(range: currentLinkData.range)
    }

    private func setLink() {
        guard let currentLinkData else { return }
        wysiwygViewModel.applyLinkOperation(.setLink(urlString: currentLinkData.url))
    }

    private func createLinkWithText() {
        guard let currentLinkData else { return }
        wysiwygViewModel.applyLinkOperation(.createLink(urlString: currentLinkData.url,
                                                        text: currentLinkData.text))
    }

    private func removeLinks() {
        wysiwygViewModel.applyLinkOperation(.removeLinks)
    }
    
    private func focusComposerIfHardwareKeyboardConnected() {
        // The simulator always detects the hardware keyboard as connected
        #if !targetEnvironment(simulator)
        if GCKeyboard.coalesced != nil {
            MXLog.info("Hardware keyboard is connected")
            state.bindings.composerFocused = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hardwareKeyboardDidConnect), name: .GCKeyboardDidConnect, object: nil)
        #endif
    }
    
    // periphery:ignore:parameters notification
    @objc private func hardwareKeyboardDidConnect(_ notification: Notification) {
        MXLog.info("Did connect hardware keyboard")
        state.bindings.composerFocused = true
    }
}

private extension LinkAction {
    var url: String? {
        guard case .edit(let url) = self else {
            return nil
        }
        return url
    }
}

private final class ComposerMentionReplacer: MentionReplacer {
    let replacementForMentionClosure: (_ urlString: String, _ text: String) -> (NSAttributedString?)
    
    init(replacementForMentionClosure: @escaping (String, String) -> (NSAttributedString?)) {
        self.replacementForMentionClosure = replacementForMentionClosure
    }
    
    // There is no internal Markdown to RTE switch implemented yet in the room so this one is never called
    func postProcessMarkdown(in attributedString: NSAttributedString) -> NSAttributedString {
        attributedString
    }
    
    // There is no internal RTE to Markdown switch implemented yet in the room so this one is never called
    func restoreMarkdown(in attributedString: NSAttributedString) -> String {
        attributedString.string
    }
    
    func replacementForMention(_ url: String, text: String) -> NSAttributedString? {
        replacementForMentionClosure(url, text)
    }
}
