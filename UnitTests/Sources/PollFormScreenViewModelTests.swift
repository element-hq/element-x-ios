//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class PollFormScreenViewModelTests: XCTestCase {
    var viewModel: PollFormScreenViewModelProtocol!
    
    var context: PollFormScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = PollFormScreenViewModel(mode: .new)
    }

    func testNewPollInitialState() async throws {
        XCTAssertEqual(context.options.count, 2)
        XCTAssertTrue(context.options.allSatisfy(\.text.isEmpty))
        XCTAssertTrue(context.question.isEmpty)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        XCTAssertFalse(context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions, until: { _ in true })
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        XCTAssertEqual(action, .cancel)
    }
    
    func testEditPollInitialState() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        XCTAssertEqual(context.options.count, 3)
        XCTAssertTrue(context.options.allSatisfy { !$0.text.isEmpty })
        XCTAssertFalse(context.question.isEmpty)
        XCTAssertTrue(context.viewState.isSubmitButtonDisabled)
        XCTAssertFalse(context.viewState.bindings.isUndisclosed)
        
        // Cancellation should work without confirmation
        let deferred = deferFulfillment(viewModel.actions, until: { _ in true })
        context.send(viewAction: .cancel)
        let action = try await deferred.fulfill()
        XCTAssertNil(context.alertInfo)
        XCTAssertEqual(action, .cancel)
    }
    
    func testNewPollInvalidEmptyOption() {
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
        context.question = "foo"
        context.options[0].text = "bla1"
        context.options[1].text = "bla2"
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .submit:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .submit)
        
        let action = try await deferred.fulfill()

        guard case .submit(let question, let options, let kind) = action else {
            XCTFail("Unexpected action")
            return
        }
        XCTAssertEqual(question, "foo")
        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0], "bla1")
        XCTAssertEqual(options[1], "bla2")
        XCTAssertEqual(kind, .disclosed)
    }

    func testEditPollSubmit() async throws {
        setupViewModel(mode: .edit(eventID: "foo", poll: .emptyDisclosed))
        context.question = "What is your favorite country?"
        context.options.append(.init(text: "France 🇫🇷"))
        XCTAssertFalse(context.viewState.isSubmitButtonDisabled)

        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .submit:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .submit)
        
        let action = try await deferred.fulfill()

        guard case .submit(let question, let options, let kind) = action else {
            XCTFail("Unexpected action")
            return
        }
        XCTAssertEqual(question, "What is your favorite country?")
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options[0], "Italy 🇮🇹")
        XCTAssertEqual(options[1], "China 🇨🇳")
        XCTAssertEqual(options[2], "USA 🇺🇸")
        XCTAssertEqual(options[3], "France 🇫🇷")
        XCTAssertEqual(kind, .disclosed)
    }
    
    private func setupViewModel(mode: PollFormMode) {
        viewModel = PollFormScreenViewModel(mode: mode)
    }
}
