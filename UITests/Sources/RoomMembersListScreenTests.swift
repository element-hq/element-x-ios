//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class RoomMembersListScreenUITests: XCTestCase {
    func testJoinedAndInvitedMembers() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        try await app.assertScreenshot()
    }
    
    func testSearchInvitedMember() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("alice\n", app: app)
        
        try await app.assertScreenshot()
    }
    
    func testSearchJoinedMember() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("bob\n", app: app)
        
        try await app.assertScreenshot()
    }
}
