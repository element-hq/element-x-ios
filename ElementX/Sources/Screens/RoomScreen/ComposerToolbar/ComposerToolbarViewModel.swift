//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    private let analyticsService: AnalyticsService
    private let draftService: ComposerDraftServiceProtocol
    
    private let mentionBuilder: MentionBuilderProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
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
    
    private var replyLoadingTask: Task<Void, Never>?

    init(wysiwygViewModel: WysiwygComposerViewModel,
         completionSuggestionService: CompletionSuggestionServiceProtocol,
         mediaProvider: MediaProviderProtocol,
         mentionDisplayHelper: MentionDisplayHelper,
         analyticsService: AnalyticsService,
         composerDraftService: ComposerDraftServiceProtocol) {
        self.wysiwygViewModel = wysiwygViewModel
        self.completionSuggestionService = completionSuggestionService
        self.analyticsService = analyticsService
        draftService = composerDraftService
        
        mentionBuilder = MentionBuilder()
        attributedStringBuilder = AttributedStringBuilder(cacheKey: "Composer", mentionBuilder: mentionBuilder)
        
        super.init(initialViewState: ComposerToolbarViewState(audioPlayerState: .init(id: .recorderPreview,
                                                                                      title: L10n.commonVoiceMessage,
                                                                                      duration: 0),
                                                              audioRecorderState: .init(),
                                                              bindings: .init()),
                   mediaProvider: mediaProvider)

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
        
        context.$viewState
            .map(\.bindings.plainComposerText)
            .removeDuplicates()
            .sink { [weak self] plainComposerText in
                self?.actionsSubject.send(.contentChanged(isEmpty: plainComposerText.string.isEmpty))
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
                if context.composerFormattingEnabled {
                    actionsSubject.send(.sendMessage(plain: wysiwygViewModel.content.markdown,
                                                     html: wysiwygViewModel.content.html,
                                                     mode: state.composerMode,
                                                     intentionalMentions: wysiwygViewModel.getMentionsState().toIntentionalMentions()))
                } else {
                    sendPlainComposerText()
                }
            }
        case .editLastMessage:
            actionsSubject.send(.editLastMessage)
        case .cancelReply:
            set(mode: .default)
        case .cancelEdit:
            if let draft = draftService.loadVolatileDraft() {
                handleLoadDraft(draft)
                draftService.clearVolatileDraft()
            } else {
                set(text: "")
                set(mode: .default)
            }
        case .attach(let attachment):
            state.bindings.composerFocused = false
            actionsSubject.send(.attach(attachment))
        case .handlePasteOrDrop(let provider):
            actionsSubject.send(.handlePasteOrDrop(provider: provider))
        case .enableTextFormatting:
            state.bindings.composerFormattingEnabled = true
            state.bindings.composerFocused = true
            
            analyticsService.trackInteraction(name: .MobileRoomComposerFormattingEnabled)
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
        case .didToggleFormattingOptions:
            if context.composerFormattingEnabled {
                guard !context.plainComposerText.string.isEmpty else {
                    return
                }
                DispatchQueue.main.async {
                    self.wysiwygViewModel.textView.flushPills()
                    self.wysiwygViewModel.setMarkdownContent(self.context.plainComposerText.string)
                }
            } else {
                context.plainComposerText = NSAttributedString(string: wysiwygViewModel.attributedContent.text.string)
            }
        }
    }

    func process(timelineAction: TimelineComposerAction) {
        switch timelineAction {
        case .setMode(mode: let mode):
            if state.composerMode.isComposingNewMessage, mode.isEdit {
                handleSaveDraft(isVolatile: true)
            }
            set(mode: mode)
        case .setText(let plainText, let htmlText):
            if let htmlText, context.composerFormattingEnabled {
                set(text: htmlText)
            } else {
                set(text: plainText)
            }
        case .removeFocus:
            state.bindings.composerFocused = false
        case .clear:
            if let draft = draftService.loadVolatileDraft() {
                handleLoadDraft(draft)
                draftService.clearVolatileDraft()
            } else {
                set(mode: .default)
                set(text: "")
            }
        }
    }
    
    func loadDraft() {
        Task {
            guard case let .success(draft) = await draftService.loadDraft(),
                  let draft else {
                return
            }
            handleLoadDraft(draft)
        }
    }
    
    func saveDraft() {
        handleSaveDraft(isVolatile: false)
    }
    
    var keyCommands: [WysiwygKeyCommand] {
        [
            .enter { [weak self] in
                self?.process(viewAction: .sendMessage)
            }
        ]
    }

    // MARK: - Private
    
    private func handleLoadDraft(_ draft: ComposerDraftProxy) {
        if let html = draft.htmlText {
            context.composerFormattingEnabled = true
            DispatchQueue.main.async {
                self.set(text: html)
            }
        } else {
            context.composerFormattingEnabled = false
            set(text: draft.plainText)
        }
        
        switch draft.draftType {
        case .newMessage:
            set(mode: .default)
        case .edit(let eventID):
            set(mode: .edit(originalItemId: .init(timelineID: "", eventID: eventID)))
        case .reply(let eventID):
            set(mode: .reply(itemID: .init(timelineID: "", eventID: eventID), replyDetails: .loading(eventID: eventID), isThread: false))
            replyLoadingTask = Task {
                let reply = switch await draftService.getReply(eventID: eventID) {
                case .success(let reply):
                    reply
                case .failure:
                    TimelineItemReply(details: .error(eventID: eventID, message: L10n.commonSomethingWentWrong), isThreaded: false)
                }
                
                guard !Task.isCancelled else {
                    return
                }
                
                set(mode: .reply(itemID: .init(timelineID: "", eventID: eventID), replyDetails: reply.details, isThread: reply.isThreaded))
            }
        }
    }
    
    private func handleSaveDraft(isVolatile: Bool) {
        let plainText: String
        let htmlText: String?
        let type: ComposerDraftProxy.ComposerDraftType
        
        if context.composerFormattingEnabled {
            if wysiwygViewModel.isContentEmpty, state.composerMode == .default {
                if isVolatile {
                    draftService.clearVolatileDraft()
                } else {
                    Task {
                        await draftService.clearDraft()
                    }
                }
                return
            }
            plainText = wysiwygViewModel.content.markdown
            htmlText = wysiwygViewModel.content.html
        } else {
            if context.plainComposerText.string.isEmpty, state.composerMode == .default {
                if isVolatile {
                    draftService.clearVolatileDraft()
                } else {
                    Task {
                        await draftService.clearDraft()
                    }
                }
                return
            }
            plainText = plainComposerContent.text
            htmlText = nil
        }
        
        switch state.composerMode {
        case .default:
            type = .newMessage
        case .edit(let itemID):
            guard let eventID = itemID.eventID else {
                MXLog.error("The event id for this message is missing")
                return
            }
            type = .edit(eventID: eventID)
        case .reply(let itemID, _, _):
            guard let eventID = itemID.eventID else {
                MXLog.error("The event id for this message is missing")
                return
            }
            type = .reply(eventID: eventID)
        default:
            if isVolatile {
                draftService.clearVolatileDraft()
            } else {
                Task {
                    await draftService.clearDraft()
                }
            }
            return
        }
        
        if isVolatile {
            draftService.saveVolatileDraft(.init(plainText: plainText, htmlText: htmlText, draftType: type))
        } else {
            Task {
                await draftService.saveDraft(.init(plainText: plainText, htmlText: htmlText, draftType: type))
            }
        }
    }
    
    private var plainComposerContent: PlainComposerContent {
        let attributedString = NSMutableAttributedString(attributedString: context.plainComposerText)

        var shouldMakeAnotherPass = false
        var userIDs = Set<String>()
        var containsAtRoom = false
        
        repeat { // Don't enumerate and mutate at the same time, big no no
            shouldMakeAnotherPass = false
            attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, stop in
                guard let value else { return }
                
                shouldMakeAnotherPass = true
                
                // Remove the attribute so it doesn't get inherited by the new string
                attributedString.removeAttribute(.link, range: range)
                
                guard let userID = attributedString.attribute(.MatrixUserID, at: range.location, effectiveRange: nil) as? String else {
                    return
                }
                
                let displayName = attributedString.attribute(.MatrixUserDisplayName, at: range.location, effectiveRange: nil)
                
                attributedString.replaceCharacters(in: range, with: "[\(displayName ?? userID)](\(value))")
                userIDs.insert(userID)
                
                stop.pointee = true
            }
        } while shouldMakeAnotherPass
        
        repeat {
            shouldMakeAnotherPass = false
            attributedString.enumerateAttribute(.MatrixAllUsersMention, in: .init(location: 0, length: attributedString.length), options: []) { value, range, stop in
                guard value != nil else { return }
                
                shouldMakeAnotherPass = true
                
                // Remove the attribute so it doesn't get inherited by the new string
                attributedString.removeAttribute(.MatrixAllUsersMention, range: range)
                
                attributedString.replaceCharacters(in: range, with: PillConstants.atRoom)
                containsAtRoom = true
                
                stop.pointee = true
            }
        } while shouldMakeAnotherPass
        
        return .init(text: attributedString.string, mentionedUserIDs: userIDs, containsAtRoomMention: containsAtRoom)
    }
    
    private func sendPlainComposerText() {
        let plainComposerContent = plainComposerContent
        actionsSubject.send(.sendMessage(plain: plainComposerContent.text, html: nil,
                                         mode: state.composerMode,
                                         intentionalMentions: .init(userIDs: plainComposerContent.mentionedUserIDs, atRoom: plainComposerContent.containsAtRoomMention)))
    }
    
    private func processVoiceMessageAction(_ action: ComposerToolbarVoiceMessageAction) {
        switch action {
        case .startRecording:
            state.bindings.composerFormattingEnabled = false
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
        
        wysiwygViewModel.mentionReplacer = ComposerMentionReplacer { [weak self] urlString, string in
            guard let self else {
                return NSMutableAttributedString(string: string)
            }
            
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
            
            if context.composerFormattingEnabled {
                wysiwygViewModel.setMention(url: url.absoluteString, name: item.id, mentionType: .user)
            } else {
                let attributedString = NSMutableAttributedString(attributedString: state.bindings.plainComposerText)
                mentionBuilder.handleUserMention(for: attributedString, in: suggestion.range, url: url, userID: item.id, userDisplayName: item.displayName)
                state.bindings.plainComposerText = attributedString
            }
        case .allUsers:
            if context.composerFormattingEnabled {
                wysiwygViewModel.setAtRoomMention()
            } else {
                let attributedString = NSMutableAttributedString(attributedString: state.bindings.plainComposerText)
                mentionBuilder.handleAllUsersMention(for: attributedString, in: suggestion.range)
                state.bindings.plainComposerText = attributedString
            }
        }
    }

    private func set(mode: ComposerMode) {
        if state.composerMode.isLoadingReply, state.composerMode.replyEventID != mode.replyEventID {
            replyLoadingTask?.cancel()
        }
        
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
        if context.composerFormattingEnabled {
            wysiwygViewModel.textView.flushPills()
            wysiwygViewModel.setHtmlContent(text)
        } else {
            let attributedString = NSMutableAttributedString(string: text)

            parseUserMentionsMarkdown(text) { range, url in
                // Call your handleUserMention function here
                attributedString.addAttribute(.link, value: url, range: range)
            }
            
            let matches = MatrixEntityRegex.allUsersRegex.matches(in: attributedString.string)
            for match in matches {
                attributedString.addAttribute(.MatrixAllUsersMention, value: true, range: match.range)
            }
            
            attributedStringBuilder.detectPermalinks(attributedString)
            
            state.bindings.plainComposerText = attributedString
        }
    }
    
    private func parseUserMentionsMarkdown(_ text: String, callback: (NSRange, URL) -> Void) {
        // Define the regex pattern
        let pattern = "\\[(.*?)\\]\\(https://matrix\\.to/#/(@.*?)\\)"
        
        // Create the regex
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        // Find matches in the input text
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        // Process each match
        for match in matches.sorted(by: { $0.range.length > $1.range.length }) {
            // Extract the display name, user ID, and full URL
            guard match.numberOfRanges == 3 else { continue }
            
            let userIDRange = match.range(at: 2)
            let fullRange = match.range(at: 0)
            
            let userID = nsText.substring(with: userIDRange)
            let fullURLString = "https://matrix.to/#/\(userID)"
            
            if let url = URL(string: fullURLString) {
                callback(fullRange, url)
            }
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

private struct PlainComposerContent {
    let text: String
    let mentionedUserIDs: Set<String>
    let containsAtRoomMention: Bool
}
