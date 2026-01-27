//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class TemplateScreenViewModelTests: XCTestCase {
    var viewModel: TemplateScreenViewModelProtocol!
    
    var context: TemplateScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        viewModel = TemplateScreenViewModel()
    }

    func testInitialState() {
        XCTAssertFalse(context.composerText.isEmpty)
        XCTAssertEqual(context.viewState.counter, 0)
    }

    func testTextField() {
        context.composerText = "123"
        context.send(viewAction: .textChanged)
        XCTAssertEqual(context.composerText, "123")
    }
    
    func testCounter() async throws {
        var deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 1 }
        context.send(viewAction: .incrementCounter)
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.counter, 1)
        
        deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 3 }
        context.send(viewAction: .incrementCounter)
        context.send(viewAction: .incrementCounter)
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.counter, 3)
        
        deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 2 }
        context.send(viewAction: .decrementCounter)
        try await deferred.fulfill()
        XCTAssertEqual(context.viewState.counter, 2)
    }
}
