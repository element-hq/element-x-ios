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

import XCTest

@testable import ElementX

@MainActor
class RoomChangePermissionsScreenViewModelTests: XCTestCase {
    var roomProxy: RoomProxyMock!
    var viewModel: RoomChangePermissionsScreenViewModelProtocol!
    
    var context: RoomChangePermissionsScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        roomProxy = RoomProxyMock(with: .init())
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                                         group: .roomDetails,
                                                         roomProxy: roomProxy,
                                                         userIndicatorController: UserIndicatorControllerMock())
    }

    func testChangeSetting() {
        // Given a screen with no changes.
        guard let index = context.settings.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        XCTAssertEqual(context.settings[index].value, .moderator)
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When updating a setting.
        let setting = RoomPermissionsSetting(title: "", value: .user, keyPath: \.roomAvatar)
        context.settings[index] = setting
        
        // Then the setting should update and the changes should be flagged.
        XCTAssertEqual(context.settings[index].value, .user)
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testSave() async throws {
        // Given a screen with changes.
        guard let index = context.settings.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        context.settings[index] = RoomPermissionsSetting(title: "", value: .user, keyPath: \.roomAvatar)
        XCTAssertEqual(context.settings[index].value, .user)
        XCTAssertTrue(context.viewState.hasChanges)
        
        // When saving changes.
        context.send(viewAction: .save)
        // Nothing to await right now,
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the changes should be applied.
        XCTAssertTrue(roomProxy.applyPowerLevelChangesCalled)
        XCTAssertEqual(roomProxy.applyPowerLevelChangesReceivedChanges, .init(roomName: 50, roomAvatar: 0, roomTopic: 50),
                       "Only the changes for this screen should be applied, the others should be nil to remain unchanged.")
    }
    
    func testSaveNoChanges() async throws {
        // Given a screen with no changes.
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When saving changes.
        context.send(viewAction: .save)
        
        // Then nothing should happen.
        XCTAssertFalse(roomProxy.applyPowerLevelChangesCalled)
    }
}
