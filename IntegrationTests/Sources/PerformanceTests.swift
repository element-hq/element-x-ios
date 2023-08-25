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

class PerformanceTests: XCTestCase {
    func testLoginFlow() throws {
        let parser = TestMeasurementParser()
        parser.capture(testCase: self) {
            let metrics: [XCTMetric] = [
                XCTApplicationLaunchMetric(),
                XCTClockMetric(),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.login)"),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.firstSync)"),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.firstRooms)"),
                XCTOSSignpostMetric(subsystem: Signposter.subsystem, category: Signposter.category, name: "\(Signposter.Name.roomFlow)")
            ]
            
            self.measure(metrics: metrics) {
                self.runLoginLogoutFlow()
            }
        }
    }
    
    private func runLoginLogoutFlow() {
        let app = Application.launch()
        
        app.login(currentTestCase: self)
        
        // Open the first room in the list.
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", A11yIdentifiers.homeScreen.roomNamePrefix)).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10.0))
        firstRoom.tap()
                
        // Go back to the room list
        let backButton = app.navigationBars.firstMatch.buttons["All Chats"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 10.0))
        backButton.tap()
        
        app.logout()
    }
}
