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
    func testJoinedMembers() {
        let app = Application.launch(.roomMembersListScreen)
        
        app.assertScreenshot(.roomMembersListScreen)
    }
    
    func testJoinedAndInvitedMembers() {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        app.assertScreenshot(.roomMembersListScreenPendingInvites)
    }
    
    func testSearchInvitedMember() {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("alice\n")
        
        app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 1)
    }
    
    func testSearchJoinedMember() {
        let app = Application.launch(.roomMembersListScreenPendingInvites)
        
        let searchBar = app.searchFields.firstMatch
        searchBar.clearAndTypeText("bob\n")
        
        app.assertScreenshot(.roomMembersListScreenPendingInvites, step: 2)
    }
}
