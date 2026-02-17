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
        context.name = "name"
        #expect(context.viewState.nameDidChange)
        #expect(context.viewState.canSave)
    }
    
    @Test
    func emptyNameCannotBeSaved() {
        context.name = ""
        #expect(!context.viewState.canSave)
    }
    
    @Test
    func avatarPickerShowsSheet() {
        context.name = "name"
        #expect(!context.showMediaSheet)
        context.send(viewAction: .presentMediaSource)
        #expect(context.showMediaSheet)
    }
    
    @Test
    func save() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        
        context.name = "name"
        context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    @Test
    func cancelWithChangesAndDiscard() async throws {
        context.name = "name"
        #expect(context.viewState.canSave)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    @Test
    func cancelWithChangesAndSave() async throws {
        context.name = "name"
        #expect(context.viewState.canSave)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
}
