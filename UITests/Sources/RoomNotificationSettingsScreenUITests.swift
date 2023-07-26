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

import ElementX
import XCTest

@MainActor
class RoomNotificationSettingsScreenUITests: XCTestCase {
    func testDefaultSetting() async throws {
        let app = Application.launch(.roomNotificationSettingsDefaultSetting)
        XCTAssertFalse(app.switches[A11yIdentifiers.roomNotificationSettingsScreen.allowCustomSetting].isOn)
        try await app.assertScreenshot(.roomNotificationSettingsDefaultSetting)
    }
    
    func testCustomSettings() async throws {
        let app = Application.launch(.roomNotificationSettingsCustomSetting)
        XCTAssert(app.switches[A11yIdentifiers.roomNotificationSettingsScreen.allowCustomSetting].isOn)
        try await app.assertScreenshot(.roomNotificationSettingsCustomSetting)
    }
}
