//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct PollFormScreenViewModelTests {
    private let timelineProxy = TimelineProxyMock(.init())
    
    private var viewModel: PollFormScreenViewModelProtocol!
    private var context: PollFormScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        viewModel = PollFormScreenViewModel(mode: .new,
                                            timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: UserIndicatorControllerMock())
    }
    
    private func makeViewModel(mode: PollFormMode = .new) -> PollFormScreenViewModelProtocol {
        PollFormScreenViewModel(mode: mode,
                                timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                analytics: ServiceLocator.shared.analytics,
                                userIndicatorController: UserIndicatorControllerMock())
    }

    @Test
    func newPollInitialState() async throws {
        #expect(context.options.count == 2)
        #expect(context.options.allSatisfy(\.text.isEmpty))
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
    func editPollInitialState() async throws {
        let viewModel = makeViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        let context = viewModel.context
        
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
    func newPollInvalidEmptyOption() {
        var testSetup = self
        testSetup.context.question = "foo"
        testSetup.context.options[0].text = "bla"
        testSetup.context.options[1].text = "bla"
        testSetup.context.send(viewAction: .addOption)
        #expect(testSetup.context.viewState.isSubmitButtonDisabled)
    }
    
    @Test
    func editPollInvalidEmptyOption() {
        let viewModel = makeViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        let context = viewModel.context
        
        context.send(viewAction: .addOption)
        #expect(context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    func editPollSubmitButtonState() {
        let viewModel = makeViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        let context = viewModel.context
        
        #expect(context.viewState.isSubmitButtonDisabled)
        context.options[0].text = "foo"
        #expect(!context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        #expect(context.alertInfo != nil)
    }

    @Test
    func newPollSubmit() async throws {
        var testSetup = self
        testSetup.context.question = "foo"
        testSetup.context.options[0].text = "bla1"
        testSetup.context.options[1].text = "bla2"
        #expect(!testSetup.context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .close }
        
        await confirmation { confirmation in
            testSetup.timelineProxy.createPollQuestionAnswersPollKindClosure = { question, options, kind in
                #expect(question == "foo")
                #expect(options.count == 2)
                #expect(options[0] == "bla1")
                #expect(options[1] == "bla2")
                #expect(kind == .disclosed)
                confirmation()
                return .success(())
            }
            testSetup.context.send(viewAction: .submit)
        }
        
        try await deferred.fulfill()
    }

    @Test
    func editPollSubmit() async throws {
        let viewModel = makeViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        let context = viewModel.context
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        #expect(!context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        await confirmation { confirmation in
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
        }
        
        try await deferred.fulfill()
    }
    
    @Test
    func deletePoll() async throws {
        let viewModel = makeViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        let context = viewModel.context
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        #expect(!context.viewState.isSubmitButtonDisabled)

        let deferredFailure = deferFailure(viewModel.actions, timeout: .seconds(1)) { $0 == .close }
        context.send(viewAction: .delete)
        
        try await deferredFailure.fulfill()
        #expect(context.alertInfo != nil, "An alert should be shown before deleting the poll.")
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        
        await confirmation { confirmation in
            timelineProxy.redactReasonClosure = { eventID, _ in
                #expect(eventID == .eventID("foo"))
                confirmation()
                return .success(())
            }
            context.alertInfo?.secondaryButton?.action?()
        }
        
        try await deferred.fulfill()
    }
}
