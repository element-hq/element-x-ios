//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class RoomDetailsEditScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsEditScreenViewModel!
    
    var userIndicatorController: UserIndicatorControllerMock!
    
    var context: RoomDetailsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    func testCannotSaveOnLanding() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testCanEdit() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.canEditName }
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.canEditAvatar)
        XCTAssertTrue(context.viewState.canEditName)
        XCTAssertTrue(context.viewState.canEditTopic)
    }
    
    func testCannotEdit() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMe]))
        XCTAssertFalse(context.viewState.canEditAvatar)
        XCTAssertFalse(context.viewState.canEditName)
        XCTAssertFalse(context.viewState.canEditTopic)
    }
    
    func testNameDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        XCTAssertTrue(context.viewState.nameDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testTopicDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.topic = "topic"
        XCTAssertTrue(context.viewState.topicDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testAvatarDidChange() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", avatarURL: .picturesDirectory, members: [.mockMeAdmin]))
        context.send(viewAction: .removeImage)
        XCTAssertTrue(context.viewState.avatarDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testEmptyNameCannotBeSaved() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = ""
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testSaveShowsSheet() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        context.name = "name"
        XCTAssertFalse(context.showMediaSheet)
        context.send(viewAction: .presentMediaSource)
        XCTAssertTrue(context.showMediaSheet)
    }
    
    func testSaveTriggersViewModelAction() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            action == .saveFinished
        }
        
        context.name = "name"
        context.send(viewAction: .save)
        
        let action = try await deferred.fulfill()
        XCTAssertEqual(action, .saveFinished)
    }
    
    func testErrorShownOnFailedFetchOfMedia() async throws {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", members: [.mockMeAdmin]))
        viewModel.didSelectMediaUrl(url: .picturesDirectory)
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(userIndicatorController.alertInfo)
    }
    
    func testDeleteAvatar() {
        setupViewModel(roomProxyConfiguration: .init(name: "Some room", avatarURL: .picturesDirectory, members: [.mockMeAdmin]))
        XCTAssertNotNil(context.viewState.avatarURL)
        context.send(viewAction: .removeImage)
        XCTAssertNil(context.viewState.avatarURL)
    }
    
    // MARK: - Private
    
    private func setupViewModel(roomProxyConfiguration: JoinedRoomProxyMockConfiguration) {
        userIndicatorController = UserIndicatorControllerMock.default
        viewModel = .init(roomProxy: JoinedRoomProxyMock(roomProxyConfiguration),
                          mediaProvider: MockMediaProvider(),
                          userIndicatorController: userIndicatorController)
    }
}
