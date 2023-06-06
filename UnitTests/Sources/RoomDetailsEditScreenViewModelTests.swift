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
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testCanEdit() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        XCTAssertTrue(context.viewState.canEditAvatar)
        XCTAssertTrue(context.viewState.canEditName)
        XCTAssertTrue(context.viewState.canEditTopic)
    }
    
    func testCannotEdit() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: []),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        XCTAssertFalse(context.viewState.canEditAvatar)
        XCTAssertFalse(context.viewState.canEditName)
        XCTAssertFalse(context.viewState.canEditTopic)
    }
    
    func testNameDidChange() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        context.name = "name"
        XCTAssertTrue(context.viewState.nameDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testTopicDidChange() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        context.topic = "topic"
        XCTAssertTrue(context.viewState.topicDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testAvatarDidChange() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room", avatarURL: .picturesDirectory))
        context.send(viewAction: .removeImage)
        XCTAssertTrue(context.viewState.avatarDidChange)
        XCTAssertTrue(context.viewState.canSave)
    }
    
    func testEmptyNameCannotBeSaved() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        context.name = ""
        XCTAssertFalse(context.viewState.canSave)
    }
    
    func testSaveShowsSheet() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        context.name = "name"
        XCTAssertFalse(context.showMediaSheet)
        context.send(viewAction: .presentMediaSource)
        XCTAssertTrue(context.showMediaSheet)
    }
    
    func testSaveTriggersViewModelAction() async {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        context.name = "name"
        context.send(viewAction: .save)
        let action = await viewModel.actions.values.first()
        XCTAssertEqual(action, .saveFinished)
    }
    
    func testErrorShownOnFailedFetchOfMedia() async throws {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room"))
        viewModel.didSelectMediaUrl(url: .picturesDirectory)
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(userIndicatorController.alertInfo)
    }
    
    func testDeleteAvatar() {
        setupViewModel(accountOwner: .mockOwner(allowedStateEvents: [.roomAvatar, .roomName, .roomTopic]),
                       roomProxyConfiguration: .init(name: "Some room", displayName: "Some room", avatarURL: .picturesDirectory))
        XCTAssertNotNil(context.viewState.avatarURL)
        context.send(viewAction: .removeImage)
        XCTAssertNil(context.viewState.avatarURL)
    }
    
    // MARK: - Private
    
    private func setupViewModel(accountOwner: RoomMemberProxyMock, roomProxyConfiguration: RoomProxyMockConfiguration) {
        userIndicatorController = UserIndicatorControllerMock.default
        viewModel = .init(accountOwner: accountOwner,
                          mediaProvider: MockMediaProvider(),
                          roomProxy: RoomProxyMock(with: roomProxyConfiguration),
                          userIndicatorController: userIndicatorController)
    }
}

private extension ImageInfo {
    static let mock: ImageInfo = .init(height: nil,
                                       width: nil,
                                       mimetype: nil,
                                       size: nil,
                                       thumbnailInfo: nil,
                                       thumbnailSource: nil,
                                       blurhash: nil)
}
