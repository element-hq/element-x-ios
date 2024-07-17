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
import Sentry

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
        
        static let appStartup = "AppStartup"
        static let appStarted = "AppStarted"
        
        static let homeserver = "homeserver"
    }
    
    static let subsystem = "ElementX"
    static let category = "PerformanceTests"
    
    private var appStartupSpan: Span
    
    init() {
        appStartupSpan = SentrySDK.startTransaction(name: Name.appStartup, operation: Name.appStarted)
    }
    
    // MARK: - Login
    
    private var loginState: OSSignpostIntervalState?
    private var loginSpan: Span?
    
    func beginLogin() {
        loginState = signposter.beginInterval(Name.login)
        loginSpan = appStartupSpan.startChild(operation: "\(Name.login)", description: "\(Name.login)")
    }
    
    func endLogin() {
        guard let loginState else {
            logger.error("Missing login state.")
            return
        }
        
        signposter.endInterval(Name.login, loginState)
        loginSpan?.finish()
        
        self.loginState = nil
        loginSpan = nil
    }
    
    // MARK: - FirstSync
    
    private var firstSyncState: OSSignpostIntervalState?
    private var firstSyncSpan: Span?
    
    func beginFirstSync(serverName: String) {
        appStartupSpan.setTag(value: serverName, key: Name.homeserver)
        
        firstSyncState = signposter.beginInterval(Name.firstSync)
        firstSyncSpan = appStartupSpan.startChild(operation: "\(Name.firstSync)", description: "\(Name.firstSync)")
    }
    
    func endFirstSync() {
        guard let firstSyncState else { return }
        
        signposter.endInterval(Name.firstSync, firstSyncState)
        firstSyncSpan?.finish()
        
        self.firstSyncState = nil
        firstSyncSpan = nil
    }
    
    // MARK: - FirstRooms
    
    private var firstRoomsState: OSSignpostIntervalState?
    private var firstRoomsSpan: Span?
    
    func beginFirstRooms() {
        firstRoomsState = signposter.beginInterval(Name.firstRooms)
        firstRoomsSpan = appStartupSpan.startChild(operation: "\(Name.firstRooms)", description: "\(Name.firstRooms)")
    }
    
    func endFirstRooms() {
        defer {
            appStartupSpan.finish()
        }
        
        guard let firstRoomsState else { return }
        
        signposter.endInterval(Name.firstRooms, firstRoomsState)
        firstRoomsSpan?.finish()
        
        self.firstRoomsState = nil
        firstRoomsSpan = nil
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
