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

class RoomMembersListScreenUITests: XCTestCase {
    func testJoinedMembers() async throws {
        let app = Application.launch(.roomMembersListScreen)
        
        try await app.assertScreenshot(.roomMembersListScreen)
    }
    
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
