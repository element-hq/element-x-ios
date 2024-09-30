//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        searchBar.clearAndTypeText("alice\n")
        
        try await app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 1)
    }
    
    func testSearchJoinedMember() async throws {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("bob\n")
        
        try await app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 2)
    }
}
