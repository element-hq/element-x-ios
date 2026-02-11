//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class UserDetailsEditScreenViewModelTests: XCTestCase {
    var viewModel: UserDetailsEditScreenViewModel!
    
    var userIndicatorController: UserIndicatorControllerMock!
    
    var context: UserDetailsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    func testCannotSaveOnLanding() {
        setupViewModel()
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testNameDidChange() {
        setupViewModel()
        context.name = "name"
        XCTAssertTrue(context.viewState.nameDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testEmptyNameCannotBeSaved() {
        setupViewModel()
        context.name = ""
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testAvatarPickerShowsSheet() {
        setupViewModel()
        context.name = "name"
        XCTAssertFalse(context.showMediaSheet)
        context.send(viewAction: .presentMediaSource)
        XCTAssertTrue(context.showMediaSheet)
    }
    
    func testSave() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        
        context.name = "name"
        context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndDiscard() async throws {
        setupViewModel()
        context.name = "name"
        XCTAssertTrue(context.viewState.canSave)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndSave() async throws {
        setupViewModel()
        context.name = "name"
        XCTAssertTrue(context.viewState.canSave)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    // MARK: - Private
    
    private func setupViewModel() {
        userIndicatorController = UserIndicatorControllerMock.default
        
        viewModel = .init(userSession: UserSessionMock(.init()),
                          mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                          userIndicatorController: userIndicatorController)
    }
}
