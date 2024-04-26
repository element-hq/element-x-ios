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

    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appSettings.richTextEditorEnabled = true
        ServiceLocator.shared.register(appSettings: appSettings)
        wysiwygViewModel = WysiwygComposerViewModel()
        completionSuggestionServiceMock = CompletionSuggestionServiceMock(configuration: .init())
        viewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                             completionSuggestionService: completionSuggestionServiceMock,
                                             mediaProvider: MockMediaProvider(),
                                             appSettings: appSettings,
                                             mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
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
        XCTAssertTrue(viewModel.state.bindings.composerActionsEnabled)
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
                                             appSettings: ServiceLocator.shared.settings,
                                             mentionDisplayHelper: ComposerMentionDisplayHelper.mock)
        
        XCTAssertEqual(viewModel.state.suggestions, suggestions)
    }
    
    func testSuggestionTrigger() {
        wysiwygViewModel.setMarkdownContent("@test")
        wysiwygViewModel.setMarkdownContent("#not_implemented_yay")
        
        // The first one is nil because when initialised the view model is empty
        XCTAssertEqual(completionSuggestionServiceMock.setSuggestionTriggerReceivedInvocations, [nil, .init(type: .user, text: "test", range: .init(location: 0, length: 5)), nil])
    }
    
    func testSelectedUserSuggestion() {
        let suggestion = SuggestionItem.user(item: .init(id: "@test:matrix.org", displayName: "Test", avatarURL: nil, range: .init()))
        viewModel.context.send(viewAction: .selectedSuggestion(suggestion))
        
        XCTAssertEqual(wysiwygViewModel.content.html, "<a href=\"https://matrix.to/#/@test:matrix.org\">Test</a> ")
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
}

private extension MentionSuggestionItem {
    static func allUsersMention(roomAvatar: URL?) -> Self {
        MentionSuggestionItem(id: PillConstants.atRoom, displayName: PillConstants.everyone, avatarURL: roomAvatar, range: .init())
    }
}
