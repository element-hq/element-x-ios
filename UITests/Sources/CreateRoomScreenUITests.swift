//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class CreateRoomScreenUITests: XCTestCase {
    func testLanding() async throws {
        let app = Application.launch(.createRoom)
        try await app.assertScreenshot(.createRoom)
    }

    func testLandingWithoutUsers() async throws {
        let app = Application.launch(.createRoomNoUsers)
        try await app.assertScreenshot(.createRoomNoUsers)
    }
    
    func testLongInputNameText() async throws {
        let app = Application.launch(.createRoom)
        
        // typeText sometimes misses letters but it's faster than typing one letter at a time
        // repeat the same letter enough times to avoid that but also to work on iPads
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].tap()
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText(.init(repeating: "x", count: 200))
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText("\n")
        try await app.assertScreenshot(.createRoom, step: 1)
    }
}
