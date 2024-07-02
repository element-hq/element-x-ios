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
@testable import ElementX
import XCTest

import WysiwygComposer

@MainActor
class ComposerToolbarViewModelTests: XCTestCase {
    private var appSettings: AppSettings!
    private var wysiwygViewModel: WysiwygComposerViewModel!
    private var viewModel: ComposerToolbarViewModel!
    private var completionSuggestionServiceMock: CompletionSuggestionServiceMock!
    private var draftServiceMock: ComposerDraftServiceMock!

    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
        wysiwygViewModel = WysiwygComposerViewModel()
        completionSuggestionServiceMock = CompletionSuggestionServiceMock(configuration: .init())
        draftServiceMock = ComposerDraftServiceMock()
        viewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                             completionSuggestionService: completionSuggestionServiceMock,
                                             mediaProvider: MockMediaProvider(),
                                             mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                             analyticsService: ServiceLocator.shared.analytics,
                                             composerDraftService: draftServiceMock)
        
        viewModel.context.composerFormattingEnabled = true
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }

    func testComposerFocus() {
        viewModel.process(roomAction: .setMode(mode: .edit(originalItemId: TimelineItemIdentifier(timelineID: "mock"))))
        XCTAssertTrue(viewModel.state.bindings.composerFocused)
        viewModel.process(roomAction: .removeFocus)
        XCTAssertFalse(viewModel.state.bindings.composerFocused)
    }

    func testComposerMode() {
        let mode: RoomScreenComposerMode = .edit(originalItemId: TimelineItemIdentifier(timelineID: "mock"))
        viewModel.process(roomAction: .setMode(mode: mode))
        XCTAssertEqual(viewModel.state.composerMode, mode)
        viewModel.process(roomAction: .clear)
        XCTAssertEqual(viewModel.state.composerMode, .default)
    }

    func testComposerModeIsPublished() {
        let mode: RoomScreenComposerMode = .edit(originalItemId: TimelineItemIdentifier(timelineID: "mock"))
        let expectation = expectation(description: "Composer mode is published")
        let cancellable = viewModel
            .context
            .$viewState
            .map(\.composerMode)
            .removeDuplicates()
            .dropFirst()
            .sink(receiveValue: { composerMode in
                XCTAssertEqual(composerMode, mode)
                expectation.fulfill()
            })

        viewModel.process(roomAction: .setMode(mode: mode))

        wait(for: [expectation], timeout: 2.0)
        cancellable.cancel()
    }

    func testHandleKeyCommand() {
        XCTAssertTrue(viewModel.keyCommands.count == 1)
    }

    func testComposerFocusAfterEnablingRTE() {
        viewModel.process(viewAction: .enableTextFormatting)
        XCTAssertTrue(viewModel.state.bindings.composerFocused)
    }

    func testRTEEnabledAfterSendingMessage() {
        viewModel.process(viewAction: .enableTextFormatting)
        XCTAssertTrue(viewModel.state.bindings.composerFocused)
        viewModel.state.composerEmpty = false
        viewModel.process(viewAction: .sendMessage)
        XCTAssertTrue(viewModel.state.bindings.composerFormattingEnabled)
    }

    func testAlertIsShownAfterLinkAction() {
        XCTAssertNil(viewModel.state.bindings.alertInfo)
        viewModel.process(viewAction: .enableTextFormatting)
        viewModel.process(viewAction: .composerAction(action: .link))
        XCTAssertNotNil(viewModel.state.bindings.alertInfo)
    }
    
    func testSuggestions() {
        let suggestions: [SuggestionItem] = [.user(item: MentionSuggestionItem(id: "@user_mention_1:matrix.org", displayName: "User 1", avatarURL: nil, range: .init())),
                                             .user(item: MentionSuggestionItem(id: "@user_mention_2:matrix.org", displayName: "User 2", avatarURL: URL.documentsDirectory, range: .init()))]
        let mockCompletionSuggestionService = CompletionSuggestionServiceMock(configuration: .init(suggestions: suggestions))
        viewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                             completionSuggestionService: mockCompletionSuggestionService,
                                             mediaProvider: MockMediaProvider(),
                                             mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                             analyticsService: ServiceLocator.shared.analytics,
                                             composerDraftService: draftServiceMock)
        
        XCTAssertEqual(viewModel.state.suggestions, suggestions)
    }
    
    func testSuggestionTrigger() async {
        wysiwygViewModel.setMarkdownContent("@test")
        wysiwygViewModel.setMarkdownContent("#not_implemented_yay")
        
        await Task.yield()
        
        // The first one is nil because when initialised the view model is empty
        XCTAssertEqual(completionSuggestionServiceMock.setSuggestionTriggerReceivedInvocations, [nil, .init(type: .user, text: "test", range: .init(location: 0, length: 5)), nil])
    }
    
    func testSelectedUserSuggestion() {
        let suggestion = SuggestionItem.user(item: .init(id: "@test:matrix.org", displayName: "Test", avatarURL: nil, range: .init()))
        viewModel.context.send(viewAction: .selectedSuggestion(suggestion))
        
        // The display name can be used for HTML injection in the rich text editor and it's useless anyway as the clients don't use it when resolving display names
        XCTAssertEqual(wysiwygViewModel.content.html, "<a href=\"https://matrix.to/#/@test:matrix.org\">@test:matrix.org</a> ")
    }
    
    func testAllUsersSuggestion() {
        let suggestion = SuggestionItem.allUsers(item: .allUsersMention(roomAvatar: nil))
        viewModel.context.send(viewAction: .selectedSuggestion(suggestion))
        
        var string = "@room"
        // swiftlint:disable:next force_unwrapping
        string.unicodeScalars.append(UnicodeScalar(String.nbsp)!)
        XCTAssertEqual(wysiwygViewModel.content.html, string)
    }
    
    func testUserMentionPillInRTE() async {
        viewModel.context.send(viewAction: .composerAppeared)
        await Task.yield()
        let userID = "@test:matrix.org"
        let suggestion = SuggestionItem.user(item: .init(id: userID, displayName: "Test", avatarURL: nil, range: .init()))
        viewModel.context.send(viewAction: .selectedSuggestion(suggestion))
        
        let attachment = wysiwygViewModel.textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) as? PillTextAttachment
        XCTAssertEqual(attachment?.pillData?.type, .user(userID: userID))
    }
    
    func testAllUsersMentionPillInRTE() async {
        viewModel.context.send(viewAction: .composerAppeared)
        await Task.yield()
        let suggestion = SuggestionItem.allUsers(item: .allUsersMention(roomAvatar: nil))
        viewModel.context.send(viewAction: .selectedSuggestion(suggestion))
        
        let attachment = wysiwygViewModel.textView.attributedText.attribute(.attachment, at: 0, effectiveRange: nil) as? PillTextAttachment
        XCTAssertEqual(attachment?.pillData?.type, .allUsers)
    }
    
    func testIntentionalMentions() async throws {
        wysiwygViewModel.setHtmlContent(
            """
            <p>Hello @room \
            and especially hello to <a href=\"https://matrix.to/#/@test:matrix.org\">Test</a></p>
            """
        )
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case let .sendMessage(_, _, _, intentionalMentions):
                return intentionalMentions == IntentionalMentions(userIDs: ["@test:matrix.org"], atRoom: true)
            default:
                return false
            }
        }
        viewModel.context.send(viewAction: .sendMessage)
        
        try await deferred.fulfill()
    }
    
    // MARK: - Draft
    
    func testSaveDraftPlainText() async {
        let expectation = expectation(description: "Wait for draft to be saved")
        draftServiceMock.saveDraftClosure = { draft in
            XCTAssertEqual(draft.plainText, "Hello world!")
            XCTAssertNil(draft.htmlText)
            XCTAssertEqual(draft.draftType, .newMessage)
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        viewModel.context.plainComposerText = .init(string: "Hello world!")
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertEqual(draftServiceMock.saveDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.clearDraftCalled)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testSaveDraftFormattedText() async {
        let expectation = expectation(description: "Wait for draft to be saved")
        draftServiceMock.saveDraftClosure = { draft in
            XCTAssertEqual(draft.plainText, "__Hello__ world!")
            XCTAssertEqual(draft.htmlText, "<strong>Hello</strong> world!")
            XCTAssertEqual(draft.draftType, .newMessage)
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = true
        wysiwygViewModel.setHtmlContent("<strong>Hello</strong> world!")
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertEqual(draftServiceMock.saveDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.clearDraftCalled)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testSaveDraftEdit() async {
        let expectation = expectation(description: "Wait for draft to be saved")
        draftServiceMock.saveDraftClosure = { draft in
            XCTAssertEqual(draft.plainText, "Hello world!")
            XCTAssertNil(draft.htmlText)
            XCTAssertEqual(draft.draftType, .edit(eventID: "testID"))
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        viewModel.process(roomAction: .setMode(mode: .edit(originalItemId: .init(timelineID: "", eventID: "testID"))))
        viewModel.context.plainComposerText = .init(string: "Hello world!")
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertEqual(draftServiceMock.saveDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.clearDraftCalled)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testSaveDraftReply() async {
        let expectation = expectation(description: "Wait for draft to be saved")
        draftServiceMock.saveDraftClosure = { draft in
            XCTAssertEqual(draft.plainText, "Hello world!")
            XCTAssertNil(draft.htmlText)
            XCTAssertEqual(draft.draftType, .reply(eventID: "testID"))
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        viewModel.process(roomAction: .setMode(mode: .reply(itemID: .init(timelineID: "",
                                                                          eventID: "testID"),
            replyDetails: .loaded(sender: .init(id: ""),
                                  eventID: "testID",
                                  eventContent: .message(.text(.init(body: "reply text")))),
            isThread: false)))
        viewModel.context.plainComposerText = .init(string: "Hello world!")
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertEqual(draftServiceMock.saveDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.clearDraftCalled)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testSaveDraftWhenEmptyReply() async {
        let expectation = expectation(description: "Wait for draft to be saved")
        draftServiceMock.saveDraftClosure = { draft in
            XCTAssertEqual(draft.plainText, "")
            XCTAssertNil(draft.htmlText)
            XCTAssertEqual(draft.draftType, .reply(eventID: "testID"))
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        viewModel.process(roomAction: .setMode(mode: .reply(itemID: .init(timelineID: "",
                                                                          eventID: "testID"),
            replyDetails: .loaded(sender: .init(id: ""),
                                  eventID: "testID",
                                  eventContent: .message(.text(.init(body: "reply text")))),
            isThread: false)))
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertEqual(draftServiceMock.saveDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.clearDraftCalled)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testClearDraftWhenEmptyNormalMessage() async {
        let expectation = expectation(description: "Wait for draft to be cleared")
        draftServiceMock.clearDraftClosure = {
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        viewModel.process(roomAction: .saveDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertFalse(draftServiceMock.saveDraftCalled)
        XCTAssertEqual(draftServiceMock.clearDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testClearDraftForNonTextMode() async {
        let expectation = expectation(description: "Wait for draft to be cleared")
        draftServiceMock.clearDraftClosure = {
            defer { expectation.fulfill() }
            return .success(())
        }
        
        viewModel.context.composerFormattingEnabled = false
        let waveformData: [Float] = Array(repeating: 1.0, count: 1000)
        viewModel.context.plainComposerText = .init(string: "Hello world!")
        viewModel.process(roomAction: .setMode(mode: .previewVoiceMessage(state: AudioPlayerState(id: .recorderPreview, duration: 10.0), waveform: .data(waveformData), isUploading: false)))
        viewModel.process(roomAction: .saveDraft)

        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertFalse(draftServiceMock.saveDraftCalled)
        XCTAssertEqual(draftServiceMock.clearDraftCallsCount, 1)
        XCTAssertFalse(draftServiceMock.loadDraftCalled)
    }
    
    func testNothingToRestore() async {
        viewModel.context.composerFormattingEnabled = false
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { expectation.fulfill() }
            return .success(nil)
        }
        
        viewModel.process(roomAction: .loadDraft)
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertFalse(viewModel.context.composerFormattingEnabled)
        XCTAssertTrue(viewModel.state.composerEmpty)
        XCTAssertEqual(viewModel.state.composerMode, .default)
    }
    
    func testRestoreNormalPlainTextMessage() async {
        viewModel.context.composerFormattingEnabled = false
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { expectation.fulfill() }
            return .success(.init(plainText: "Hello world!",
                                  htmlText: nil,
                                  draftType: .newMessage))
        }
        viewModel.process(roomAction: .loadDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertFalse(viewModel.context.composerFormattingEnabled)
        XCTAssertEqual(viewModel.state.composerMode, .default)
        XCTAssertEqual(viewModel.context.plainComposerText, NSAttributedString(string: "Hello world!"))
    }
    
    func testRestoreNormalFormattedTextMessage() async {
        viewModel.context.composerFormattingEnabled = false
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { expectation.fulfill() }
            return .success(.init(plainText: "__Hello__ world!",
                                  htmlText: "<strong>Hello</strong> world!",
                                  draftType: .newMessage))
        }
        viewModel.process(roomAction: .loadDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertTrue(viewModel.context.composerFormattingEnabled)
        XCTAssertEqual(viewModel.state.composerMode, .default)
        XCTAssertEqual(wysiwygViewModel.content.html, "<strong>Hello</strong> world!")
        XCTAssertEqual(wysiwygViewModel.content.markdown, "__Hello__ world!")
    }
    
    func testRestoreEdit() async {
        viewModel.context.composerFormattingEnabled = false
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { expectation.fulfill() }
            return .success(.init(plainText: "Hello world!",
                                  htmlText: nil,
                                  draftType: .edit(eventID: "testID")))
        }
        viewModel.process(roomAction: .loadDraft)
        
        await fulfillment(of: [expectation], timeout: 10)
        XCTAssertFalse(viewModel.context.composerFormattingEnabled)
        XCTAssertEqual(viewModel.state.composerMode, .edit(originalItemId: .init(timelineID: "", eventID: "testID")))
        XCTAssertEqual(viewModel.context.plainComposerText, NSAttributedString(string: "Hello world!"))
    }
    
    func testRestoreReply() async {
        let testEventID = "testID"
        let text = "Hello world!"
        let loadedReply = TimelineItemReplyDetails.loaded(sender: .init(id: "userID",
                                                                        displayName: "Username"),
                                                          eventID: testEventID,
                                                          eventContent: .message(.text(.init(body: "Reply text"))))
        
        viewModel.context.composerFormattingEnabled = false
        let draftExpectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { draftExpectation.fulfill() }
            return .success(.init(plainText: text,
                                  htmlText: nil,
                                  draftType: .reply(eventID: testEventID)))
        }
        
        let loadReplyExpectation = expectation(description: "Wait for reply to be loaded")
        draftServiceMock.getReplyEventIDClosure = { eventID in
            defer { loadReplyExpectation.fulfill() }
            XCTAssertEqual(eventID, testEventID)
            try? await Task.sleep(for: .seconds(1))
            return .success(.init(details: loadedReply,
                                  isThreaded: true))
        }
        viewModel.process(roomAction: .loadDraft)
        
        await fulfillment(of: [draftExpectation], timeout: 10)
        XCTAssertFalse(viewModel.context.composerFormattingEnabled)
        // Testing the loading state first
        XCTAssertEqual(viewModel.state.composerMode, .reply(itemID: .init(timelineID: "", eventID: testEventID),
                                                            replyDetails: .loading(eventID: testEventID),
                                                            isThread: false))
        XCTAssertEqual(viewModel.context.plainComposerText, NSAttributedString(string: text))
        
        await fulfillment(of: [loadReplyExpectation], timeout: 10)
        XCTAssertEqual(viewModel.state.composerMode, .reply(itemID: .init(timelineID: "", eventID: testEventID),
                                                            replyDetails: loadedReply,
                                                            isThread: true))
    }
    
    func testRestoreReplyAndCancelReplyMode() async {
        let testEventID = "testID"
        let text = "Hello world!"
        let loadedReply = TimelineItemReplyDetails.loaded(sender: .init(id: "userID",
                                                                        displayName: "Username"),
                                                          eventID: testEventID,
                                                          eventContent: .message(.text(.init(body: "Reply text"))))
        
        viewModel.context.composerFormattingEnabled = false
        let draftExpectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadDraftClosure = {
            defer { draftExpectation.fulfill() }
            return .success(.init(plainText: text,
                                  htmlText: nil,
                                  draftType: .reply(eventID: testEventID)))
        }
        
        let loadReplyExpectation = expectation(description: "Wait for reply to be loaded")
        draftServiceMock.getReplyEventIDClosure = { eventID in
            defer { loadReplyExpectation.fulfill() }
            XCTAssertEqual(eventID, testEventID)
            try? await Task.sleep(for: .seconds(1))
            return .success(.init(details: loadedReply,
                                  isThreaded: true))
        }
        viewModel.process(roomAction: .loadDraft)
        
        await fulfillment(of: [draftExpectation], timeout: 10)
        XCTAssertFalse(viewModel.context.composerFormattingEnabled)
        // Testing the loading state first
        XCTAssertEqual(viewModel.state.composerMode, .reply(itemID: .init(timelineID: "", eventID: testEventID),
                                                            replyDetails: .loading(eventID: testEventID),
                                                            isThread: false))
        XCTAssertEqual(viewModel.context.plainComposerText, NSAttributedString(string: text))
        
        // Now we change the state to cancel the reply mode update
        viewModel.process(viewAction: .cancelReply)
        await fulfillment(of: [loadReplyExpectation], timeout: 10)
        XCTAssertEqual(viewModel.state.composerMode, .default)
    }
    
    func testSaveVolatileDraftWhenEditing() {
        viewModel.context.composerFormattingEnabled = false
        viewModel.context.plainComposerText = .init(string: "Hello world!")
        viewModel.process(roomAction: .setMode(mode: .edit(originalItemId: .random)))
        
        let draft = draftServiceMock.saveVolatileDraftReceivedDraft
        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.plainText, "Hello world!")
        XCTAssertNil(draft?.htmlText)
        XCTAssertEqual(draft?.draftType, .newMessage)
    }
    
    func testRestoreVolatileDraftWhenCancellingEdit() async {
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadVolatileDraftClosure = {
            defer { expectation.fulfill() }
            return .init(plainText: "Hello world",
                         htmlText: nil,
                         draftType: .newMessage)
        }
        
        viewModel.process(viewAction: .cancelEdit)
        await fulfillment(of: [expectation])
    }
    
    func testRestoreVolatileDraftWhenClearing() async {
        let expectation = expectation(description: "Wait for draft to be restored")
        draftServiceMock.loadVolatileDraftClosure = {
            defer { expectation.fulfill() }
            return .init(plainText: "Hello world",
                         htmlText: nil,
                         draftType: .newMessage)
        }
        
        viewModel.process(roomAction: .clear)
        await fulfillment(of: [expectation])
    }
}

private extension MentionSuggestionItem {
    static func allUsersMention(roomAvatar: URL?) -> Self {
        MentionSuggestionItem(id: PillConstants.atRoom, displayName: PillConstants.everyone, avatarURL: roomAvatar, range: .init())
    }
}
