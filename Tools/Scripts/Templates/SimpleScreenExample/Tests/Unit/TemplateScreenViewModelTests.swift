//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct TemplateScreenViewModelTests {
    var viewModel: TemplateScreenViewModelProtocol
    
    var context: TemplateScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        viewModel = TemplateScreenViewModel()
    }
    
    @Test
    func initialState() {
        #expect(!context.composerText.isEmpty)
        #expect(context.viewState.counter == 0)
    }
    
    @Test
    func textField() {
        context.composerText = "123"
        context.send(viewAction: .textChanged)
        #expect(context.composerText == "123")
    }
    
    @Test
    func counter() async throws {
        var deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 1 }
        context.send(viewAction: .incrementCounter)
        try await deferred.fulfill()
        #expect(context.viewState.counter == 1)
        
        deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 3 }
        context.send(viewAction: .incrementCounter)
        context.send(viewAction: .incrementCounter)
        try await deferred.fulfill()
        #expect(context.viewState.counter == 3)
        
        deferred = deferFulfillment(context.observe(\.viewState.counter)) { $0 == 2 }
        context.send(viewAction: .decrementCounter)
        try await deferred.fulfill()
        #expect(context.viewState.counter == 2)
    }
}
