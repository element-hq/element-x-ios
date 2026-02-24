//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import Testing

@Suite
@MainActor
struct RoomDetailsEditScreenViewModelTests {
    var viewModel: RoomDetailsEditScreenViewModel!
    
    var userIndicatorController: UserIndicatorControllerMock!
    
    var context: RoomDetailsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func cannotSaveOnLanding() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        #expect(!context.viewState.canSave)
    }
    
    @Test
    mutating func canEdit() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.canEditName }
        try await deferred.fulfill()
        
        #expect(context.viewState.canEditAvatar)
        #expect(context.viewState.canEditName)
        #expect(context.viewState.canEditTopic)
    }
    
    @Test
    mutating func cannotEdit() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMe]))
        #expect(!context.viewState.canEditAvatar)
        #expect(!context.viewState.canEditName)
        #expect(!context.viewState.canEditTopic)
    }
    
    @Test
    mutating func nameDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        #expect(context.viewState.nameDidChange)
        #expect(context.viewState.canSave)
    }
    
    @Test
    mutating func topicDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.topic = "topic"
        #expect(context.viewState.topicDidChange)
        #expect(context.viewState.canSave)
    }
    
    @Test
    mutating func avatarDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", avatarURL: .mockMXCAvatar, members: [.mockMeAdmin]))
        context.send(viewAction: .removeImage)
        #expect(context.viewState.avatarDidChange)
        #expect(context.viewState.canSave)
    }
    
    @Test
    mutating func emptyNameCannotBeSaved() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = ""
        #expect(!context.viewState.canSave)
    }
    
    @Test
    mutating func avatarPickerShowsSheet() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        #expect(!context.showMediaSheet)
        context.send(viewAction: .presentMediaSource)
        #expect(context.showMediaSheet)
    }
    
    @Test
    mutating func saveTriggersViewModelAction() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            action == .saveFinished
        }
        
        context.name = "name"
        context.send(viewAction: .save)
        
        let action = try await deferred.fulfill()
        #expect(action == .saveFinished)
    }
    
    @Test
    mutating func cancelWithoutChanges() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        #expect(!context.viewState.canSave)
        #expect(context.alertInfo == nil)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .cancel }
        context.send(viewAction: .cancel)
        try await deferred.fulfill()
        #expect(context.alertInfo == nil)
    }
    
    @Test
    mutating func cancelWithChangesAndDiscard() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        #expect(context.viewState.canSave)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .cancel }
        context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    @Test
    mutating func cancelWithChangesAndSave() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        #expect(context.viewState.canSave)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .saveFinished }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    @Test
    mutating func errorShownOnFailedFetchOfMedia() async {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        viewModel.didSelectMediaUrl(url: .picturesDirectory)
        try? await Task.sleep(for: .milliseconds(100))
        #expect(context.alertInfo != nil)
    }
    
    @Test
    mutating func deleteAvatar() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", avatarURL: .mockMXCAvatar, members: [.mockMeAdmin]))
        #expect(context.viewState.avatarURL != nil)
        context.send(viewAction: .removeImage)
        #expect(context.viewState.avatarURL == nil)
    }
    
    // MARK: - Private
    
    private mutating func setupViewModel(roomProxyConfiguration: JoinedRoomProxyMockConfiguration) {
        userIndicatorController = UserIndicatorControllerMock.default
        viewModel = .init(roomProxy: JoinedRoomProxyMock(roomProxyConfiguration),
                          userSession: UserSessionMock(.init()),
                          mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                          userIndicatorController: userIndicatorController)
    }
}
