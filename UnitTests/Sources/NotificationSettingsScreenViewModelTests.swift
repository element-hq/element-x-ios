//
// Copyright 2023 New Vector Ltd
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
class NotificationSettingsScreenViewModelTests: XCTestCase {
    private var viewModel: NotificationsSettingsScreenViewModelProtocol!
    private var context: NotificationsSettingsScreenViewModelType.Context!
    private var appSettings: AppSettings!
    private var userNotificationCenter: UserNotificationCenterMock!
    
    @MainActor override func setUpWithError() throws {
        AppSettings.reset()
        
        userNotificationCenter = UserNotificationCenterMock()
        userNotificationCenter.getAuthorizationStatusReturnValue = .authorized
        appSettings = AppSettings()
        viewModel = NotificationsSettingsScreenViewModel(appSettings: appSettings,
                                                         userNotificationCenter: userNotificationCenter)
        context = viewModel.context
    }
    
    func testEnableNotifications() {
        appSettings.enableNotifications = false
        context.send(viewAction: .changedEnableNotifications)
        XCTAssertTrue(appSettings.enableNotifications)
    }
    
    func testOptOut() {
        appSettings.enableNotifications = true
        context.send(viewAction: .changedEnableNotifications)
        XCTAssertFalse(appSettings.enableNotifications)
    }
}
