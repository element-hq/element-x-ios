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
class RoomScreenUITests: XCTestCase {
    func testPlainNoAvatar() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomPlainNoAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.staticTexts["roomAvatarPlaceholderImage"].exists)

        app.assertScreenshot(.roomPlainNoAvatar)
    }

    func testEncryptedWithAvatar() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomEncryptedWithAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.images["roomAvatarImage"].waitForExistence(timeout: 1))

        app.assertScreenshot(.roomEncryptedWithAvatar)
    }
    
    func testSmallTimelineLayout() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimeline)
        
        // The messages should be bottom aligned.
        app.assertScreenshot(.roomSmallTimeline)
    }
    
    func testSmallTimelineWithIncomingAndPagination() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimelineIncomingAndSmallPagination)
        
        // Wait for both the incoming message and the pagination chunk.
        XCTAssert(app.staticTexts["Bob"].waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["Helena"].waitForExistence(timeout: 2))

        // The messages should still be bottom aligned after the new items are added.
        app.assertScreenshot(.roomSmallTimelineIncomingAndSmallPagination)
    }
    
    func testSmallTimelineWithLargePagination() async throws {
        let signal = try UITestSignalServer()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimelineLargePagination)
        
        try await signal.connect()
        try await signal.send(.paginate)
        try await signal.receive()
        
        // Pagination finished, wait for the timeline to update
        try await Task.sleep(for: .milliseconds(500))

        // The bottom of the timeline should remain visible with more items added above.
        app.assertScreenshot(.roomSmallTimelineLargePagination)
    }
    
    func testBackPaginationInMiddle() async throws {
        let server = try UITestSignalServer()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomMiddlePagination)
        
        try await server.connect()
        
        app.tables.element.swipeDown()
//        while !app.staticTexts["Syncing"].exists {
//        }
        
        // The messages should be bottom aligned.
        app.assertScreenshot(.roomMiddlePagination, step: 0)
        
        try await server.send(.paginate)
        try await server.receive()
        
//        while app.staticTexts["Syncing"].exists {
//            continue
//        }
        
        // The messages should be bottom aligned.
        app.assertScreenshot(.roomMiddlePagination, step: 1)
    }
    
    func testBackPaginationAtTop() async throws {
        let server = try UITestSignalServer()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomTopPagination)
        
        try await server.connect()
        try await server.send(.paginate)
        try await server.receive()

        // The messages should be bottom aligned.
        app.assertScreenshot(.roomTopPagination)
    }
}
