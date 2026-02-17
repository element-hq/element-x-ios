//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct UserDetailsEditScreenViewModelTests {
    private var viewModel: UserDetailsEditScreenViewModel!
    private var userIndicatorController: UserIndicatorControllerMock!
    
    private var context: UserDetailsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        userIndicatorController = UserIndicatorControllerMock.default
        viewModel = .init(userSession: UserSessionMock(.init()),
                          mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                          userIndicatorController: userIndicatorController)
    }
    
    @Test
    func cannotSaveOnLanding() {
        #expect(!context.viewState.canSave)
    }
    
    @Test
    func nameDidChange() {
        var testSetup = self
        testSetup.context.name = "name"
        #expect(testSetup.context.viewState.nameDidChange)
        #expect(testSetup.context.viewState.canSave)
    }
    
    @Test
    func emptyNameCannotBeSaved() {
        var testSetup = self
        testSetup.context.name = ""
        #expect(!testSetup.context.viewState.canSave)
    }
    
    @Test
    func avatarPickerShowsSheet() {
        var testSetup = self
        testSetup.context.name = "name"
        #expect(!testSetup.context.showMediaSheet)
        testSetup.context.send(viewAction: .presentMediaSource)
        #expect(testSetup.context.showMediaSheet)
    }
    
    @Test
    func save() async throws {
        var testSetup = self
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .dismiss }
        
        testSetup.context.name = "name"
        testSetup.context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    @Test
    func cancelWithChangesAndDiscard() async throws {
        var testSetup = self
        testSetup.context.name = "name"
        #expect(testSetup.context.viewState.canSave)
        #expect(testSetup.context.alertInfo == nil)
        
        testSetup.context.send(viewAction: .cancel)
        
        #expect(testSetup.context.alertInfo != nil)
        
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .dismiss }
        testSetup.context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    @Test
    func cancelWithChangesAndSave() async throws {
        var testSetup = self
        testSetup.context.name = "name"
        #expect(testSetup.context.viewState.canSave)
        #expect(testSetup.context.alertInfo == nil)
        
        testSetup.context.send(viewAction: .cancel)
        
        #expect(testSetup.context.alertInfo != nil)
        
        let deferred = deferFulfillment(testSetup.viewModel.actions) { $0 == .dismiss }
        testSetup.context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
}
