//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    
    // MARK: - App Startup
    
    private var appStartupTransaction: Span?
    
    // We have a manual start method because we need to configure the ServiceLocator *before* we configure
    // Sentry but this class is created in the AnalyticsService and so spans and transactions are dropped
    // until Sentry has been configured. Therefore doing this in the init doesn't work.
    func start() {
        appStartupTransaction = SentrySDK.startTransaction(name: Name.appStartup, operation: Name.appStarted)
    }
    
    // MARK: - Login
    
    private var loginState: OSSignpostIntervalState?
    private var loginTransaction: Span?
    private var loginSpan: Span?
    
    func beginLogin() {
        loginState = signposter.beginInterval(Name.login)
        loginTransaction = SentrySDK.startTransaction(name: "\(Name.login)", operation: "\(Name.login)")
        loginSpan = appStartupTransaction?.startChild(operation: "\(Name.login)", description: "\(Name.login)")
    }
    
    func endLogin() {
        guard let loginState else {
            logger.error("Missing login state.")
            return
        }
        
        signposter.endInterval(Name.login, loginState)
        loginTransaction?.finish()
        loginSpan?.finish()
        
        self.loginState = nil
        loginTransaction = nil
        loginSpan = nil
    }
    
    // MARK: - FirstSync
    
    private var firstSyncState: OSSignpostIntervalState?
    private var firstSyncTransaction: Span?
    private var firstSyncSpan: Span?
    
    func beginFirstSync(serverName: String) {
        appStartupTransaction?.setTag(value: serverName, key: Name.homeserver)
        
        firstSyncState = signposter.beginInterval(Name.firstSync)
        
        firstSyncTransaction = SentrySDK.startTransaction(name: "\(Name.firstSync)", operation: "\(Name.firstSync)")
        firstSyncTransaction?.setTag(value: serverName, key: Name.homeserver)
        
        firstSyncSpan = appStartupTransaction?.startChild(operation: "\(Name.firstSync)", description: "\(Name.firstSync)")
    }
    
    func endFirstSync() {
        guard let firstSyncState else { return }
        
        signposter.endInterval(Name.firstSync, firstSyncState)
        firstSyncTransaction?.finish()
        firstSyncSpan?.finish()
        
        self.firstSyncState = nil
        firstSyncTransaction = nil
        firstSyncSpan = nil
    }
    
    // MARK: - FirstRooms
    
    private var firstRoomsState: OSSignpostIntervalState?
    private var firstRoomsTransaction: Span?
    private var firstRoomsSpan: Span?
    
    func beginFirstRooms() {
        firstRoomsState = signposter.beginInterval(Name.firstRooms)
        firstRoomsTransaction = SentrySDK.startTransaction(name: "\(Name.firstRooms)", operation: "\(Name.firstRooms)")
        firstRoomsSpan = appStartupTransaction?.startChild(operation: "\(Name.firstRooms)", description: "\(Name.firstRooms)")
    }
    
    func endFirstRooms() {
        defer {
            appStartupTransaction?.finish()
        }
        
        guard let firstRoomsState else { return }
        
        signposter.endInterval(Name.firstRooms, firstRoomsState)
        firstRoomsTransaction?.finish()
        firstRoomsSpan?.finish()
        
        self.firstRoomsState = nil
        firstRoomsTransaction = nil
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
