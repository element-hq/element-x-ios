//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class RoomMembersListScreenUITests: XCTestCase {
    func testJoinedAndInvitedMembers() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        try await app.assertScreenshot(.roomMembersListScreenPendingInvites)
    }
    
    func testSearchInvitedMember() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("alice\n", app: app)
        
        try await app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 1, delay: .seconds(0.5))
    }
    
    func testSearchJoinedMember() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("bob\n", app: app)
        
        try await app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 2, delay: .seconds(0.5))
    }
}
