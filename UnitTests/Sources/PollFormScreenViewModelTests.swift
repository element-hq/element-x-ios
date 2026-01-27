//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class PollFormScreenViewModelTests: XCTestCase {
    let timelineProxy = TimelineProxyMock(.init())
    
    var viewModel: PollFormScreenViewModelProtocol!
    var context: PollFormScreenViewModelType.Context {
        viewModel.context
    }

    func testNewPollInitialState() async throws {
        setupViewModel()
        
        XCTAssertEqual(context.options.count, 2)
        XCTAssertTrue(context.options.allSatisfy(\.text.isEmpty))
        XCTAssertTrue(context.question.isEmpty)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        XCTAssertFalse(context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        XCTAssertEqual(action, .close)
    }
    
    func testEditPollInitialState() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        XCTAssertEqual(context.options.count, 3)
        XCTAssertTrue(context.options.allSatisfy { !$0.text.isEmpty })
        XCTAssertFalse(context.question.isEmpty)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        XCTAssertFalse(context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions) { _ in true }
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        XCTAssertEqual(action, .close)
    }
    
    func testNewPollInvalidEmptyOption() {
        setupViewModel()
        
        context.question = "foo"
        context.options[0].text = "bla"
        context.options[1].text = "bla"
        context.send(viewAction: .addOption)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
    }
    
    func testEditPollInvalidEmptyOption() {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.send(viewAction: .addOption)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testEditPollSubmitButtonState() {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        context.options[0].text = "foo"
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)
        
        // Cancellation requires a confirmation
        context.send(viewAction: .cancel)
        XCTAssertNotNil(context.alertInfo)
    }

    func testNewPollSubmit() async throws {
        setupViewModel()
        
        context.question = "foo"
        context.options[0].text = "bla1"
        context.options[1].text = "bla2"
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        let expectation = XCTestExpectation(description: "Create poll")
        timelineProxy.createPollQuestionAnswersPollKindClosure = { question, options, kind in
            XCTAssertEqual(question, "foo")
            XCTAssertEqual(options.count, 2)
            XCTAssertEqual(options[0], "bla1")
            XCTAssertEqual(options[1], "bla2")
            XCTAssertEqual(kind, .disclosed)
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .submit)
        
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }

    func testEditPollSubmit() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        let expectation = XCTestExpectation(description: "Edit poll")
        timelineProxy.editPollOriginalQuestionAnswersPollKindClosure = { eventID, question, options, kind in
            XCTAssertEqual(eventID, "foo")
            XCTAssertEqual(question, "What is your favorite country?")
            XCTAssertEqual(options.count, 4)
            XCTAssertEqual(options[0], "Italy 🇮🇹")
            XCTAssertEqual(options[1], "China 🇨🇳")
            XCTAssertEqual(options[2], "USA 🇺🇸")
            XCTAssertEqual(options[3], "France 🇫🇷")
            XCTAssertEqual(kind, .disclosed)
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .submit)
        
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }
    
    func testDeletePoll() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)

        let deferredFailure = deferFailure(viewModel.actions, timeout: 1, message: "The alert should be shown.") { $0 == .close }
        context.send(viewAction: .delete)
        
        try await deferredFailure.fulfill()
        XCTAssertNotNil(context.alertInfo, "An alert should be shown before deleting the poll.")
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .close }
        let expectation = XCTestExpectation(description: "Delete poll")
        timelineProxy.redactReasonClosure = { eventID, _ in
            XCTAssertEqual(eventID, .eventID("foo"))
            expectation.fulfill()
            return .success(())
        }
        context.alertInfo?.secondaryButton?.action?()
        
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(mode: PollFormMode = .new) {
        viewModel = PollFormScreenViewModel(mode: mode,
                                            timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: UserIndicatorControllerMock())
    }
}
