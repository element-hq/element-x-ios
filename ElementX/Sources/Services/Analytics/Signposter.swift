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

import OSLog

/// A simple wrapper around OSSignposter for easy performance testing.
class Signposter {
    /// The underlying signposter.
    private let signposter = OSSignposter(subsystem: subsystem, category: category)
    /// A logger instance to capture any errors.
    private let logger = Logger(subsystem: subsystem, category: category)
    
    /// Signpost name constants.
    enum Name {
        static let login: StaticString = "Login"
        static let firstSync: StaticString = "FirstSync"
        static let firstRooms: StaticString = "FirstRooms"
        static let roomFlow: StaticString = "RoomFlow"
    }
    
    static let subsystem = "ElementX"
    static let category = "PerformanceTests"
    
    // MARK: - Login
    
    private var loginState: OSSignpostIntervalState?
    
    func beginLogin() {
        loginState = signposter.beginInterval(Name.login)
    }
    
    func endLogin() {
        guard let loginState else {
            logger.error("Missing login state.")
            return
        }
        
        signposter.endInterval(Name.login, loginState)
        self.loginState = nil
    }
    
    // MARK: - FirstSync
    
    private var firstSyncState: OSSignpostIntervalState?
    
    func beginFirstSync() {
        firstSyncState = signposter.beginInterval(Name.firstSync)
    }
    
    func endFirstSync() {
        guard let firstSyncState else { return }
        
        signposter.endInterval(Name.firstSync, firstSyncState)
        self.firstSyncState = nil
    }
    
    // MARK: - FirstRooms
    
    private var firstRoomsState: OSSignpostIntervalState?
    
    func beginFirstRooms() {
        firstRoomsState = signposter.beginInterval(Name.firstRooms)
    }
    
    func endFirstRooms() {
        guard let firstRoomsState else { return }
        
        signposter.endInterval(Name.firstRooms, firstRoomsState)
        self.firstRoomsState = nil
    }
    
    // MARK: - Room Flow
    
    private var roomFlowState: OSSignpostIntervalState?
    
    func beginRoomFlow(_ name: String) {
        roomFlowState = signposter.beginInterval(Name.roomFlow)
        signposter.emitEvent("RoomName", "\(name, privacy: .auto(mask: .hash))")
    }
    
    func endRoomFlow() {
        guard let roomFlowState else { return }
        
        signposter.endInterval(Name.roomFlow, roomFlowState)
        self.roomFlowState = nil
    }
}
