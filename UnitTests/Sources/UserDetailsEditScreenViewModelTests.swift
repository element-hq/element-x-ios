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
struct UserDetailsEditScreenViewModelTests {
    private var viewModel: UserDetailsEditScreenViewModel!
    private var userIndicatorController: UserIndicatorControllerMock!
    private var appMediator: AppMediatorMock!
    
    private var context: UserDetailsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        userIndicatorController = UserIndicatorControllerMock()
        appMediator = AppMediatorMock(.init())
        viewModel = .init(userSession: UserSessionMock(.init()),
                          mediaUploadingPreprocessor: MediaUploadingPreprocessor(userSettings: .mock()),
                          userIndicatorController: userIndicatorController,
                          appMediator: appMediator)
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
    
    @Test
    func cameraPickerOpensWhenTheCameraIsAvailable() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0 == .displayCameraPicker }
        context.send(viewAction: .displayCameraPicker)
        try await deferred.fulfill()
    }
    
    @Test
    func cameraPickerShowsAnErrorWhenTheCameraIsUnavailable() async throws {
        appMediator.isCameraAvailable = false
        
        let deferredFailure = deferFailure(viewModel.actions, timeout: .seconds(1)) { $0 == .displayCameraPicker }
        context.send(viewAction: .displayCameraPicker)
        try await deferredFailure.fulfill()
        
        #expect(userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == L10n.errorCameraUnavailable)
    }
}
