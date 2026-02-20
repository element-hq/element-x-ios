//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct PollFormScreenViewModelTests {
    private let timelineProxy = TimelineProxyMock(.init())
    
    private var viewModel: PollFormScreenViewModelProtocol!
    private var context: PollFormScreenViewModelType.Context {
        viewModel.context
    }

    @Test
    mutating func newPollInitialState() async throws {
        setupViewModel()
        #expect(context.options.count == 2)
        // This due to a bug in Swift testing that raises an error when allSatisfy is used in an #expect
        let isEmpty = context.options.allSatisfy(\.text.isEmpty)
        #expect(isEmpty)
        #expect(context.question.isEmpty)
        #expect(context.viewState.isSubmitButtonDisabled)
        #expect(!context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        #expect(context.alertInfo == nil)
        #expect(action == .close)
    }
    
    @Test
    mutating func editPollInitialState() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        #expect(context.options.count == 3)
        #expect(context.options.allSatisfy { !$0.text.isEmpty })
        #expect(!context.question.isEmpty)
        #expect(context.viewState.isSubmitButtonDisabled)
        #expect(!context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        #expect(context.alertInfo == nil)
        #expect(action == .close)
    }
    
    @Test
    mutating func newPollInvalidEmptyOption() {
        setupViewModel()
        context.question = "foo"
        context.options[0].text = "bla"
        context.options[1].text = "bla"
        context.send(viewAction: .addOption)
        #expect(context.viewState.isSubmitButtonDisabled)
    }
    
    @Test
    mutating func editPollInvalidEmptyOption() {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.send(viewAction: .addOption)
        #expect(context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    mutating func editPollSubmitButtonState() {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        #expect(context.viewState.isSubmitButtonDisabled)
        context.options[0].text = "foo"
        #expect(!context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        #expect(context.alertInfo != nil)
    }

    @Test
    mutating func newPollSubmit() async throws {
        setupViewModel()
        context.question = "foo"
        context.options[0].text = "bla1"
        context.options[1].text = "bla2"
        #expect(!context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        try await confirmation { confirmation in
            timelineProxy.createPollQuestionAnswersPollKindClosure = { question, options, kind in
                #expect(question == "foo")
                #expect(options.count == 2)
                #expect(options[0] == "bla1")
                #expect(options[1] == "bla2")
                #expect(kind == .disclosed)
                confirmation()
                return .success(())
            }
            context.send(viewAction: .submit)
            
            try await deferred.fulfill()
        }
    }

    @Test
    mutating func editPollSubmit() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        #expect(!context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        try await confirmation { confirmation in
            timelineProxy.editPollOriginalQuestionAnswersPollKindClosure = { eventID, question, options, kind in
                #expect(eventID == "foo")
                #expect(question == "What is your favorite country?")
                #expect(options.count == 4)
                #expect(options[0] == "Italy 🇮🇹")
                #expect(options[1] == "China 🇨🇳")
                #expect(options[2] == "USA 🇺🇸")
                #expect(options[3] == "France 🇫🇷")
                #expect(kind == .disclosed)
                confirmation()
                return .success(())
            }
            context.send(viewAction: .submit)
            
            try await deferred.fulfill()
        }
    }
    
    @Test
    mutating func deletePoll() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        #expect(!context.viewState.isSubmitButtonDisabled)

        let deferredFailure = deferFailure(viewModel.actions, timeout: .seconds(1)) { $0 == .close }
        context.send(viewAction: .delete)
        
        try await deferredFailure.fulfill()
        #expect(context.alertInfo != nil, "An alert should be shown before deleting the poll.")
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        try await confirmation { confirmation in
            var redactReasonCalled = false
            timelineProxy.redactReasonClosure = { eventID, _ in
                defer {
                    confirmation()
                    redactReasonCalled = true
                }
                #expect(eventID == .eventID("foo"))
                return .success(())
            }
            context.alertInfo?.secondaryButton?.action?()
            
            try await deferred.fulfill()
            
            // Since the redactReasonClosure is called asynchronously after closing the alert
            // We need to actively wait for the redactReasonClosure to be called before fulfilling the test.
            while !redactReasonCalled {
                await Task.yield()
            }
        }
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(mode: PollFormMode = .new) {
        viewModel = PollFormScreenViewModel(mode: mode,
                                            timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: UserIndicatorControllerMock())
    }
}
