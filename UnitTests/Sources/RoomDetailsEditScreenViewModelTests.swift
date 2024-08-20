//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
