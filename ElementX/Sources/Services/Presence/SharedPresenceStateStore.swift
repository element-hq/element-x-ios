//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol SharedPresenceStateStoreProtocol: Sendable {
    var mainAppActivityStateSnapshot: MainAppActivityStateSnapshot { get nonmutating set }
    
    func updateMainAppActivityState(_ state: MainAppActivityState, systemUptime: TimeInterval)
}

nonisolated struct SharedPresenceStateStore: SharedPresenceStateStoreProtocol {
    private static let mainAppActivityStateSnapshotKey = "mainAppActivityStateSnapshot"
    
    private let suiteName: String
    
    init(suiteName: String) {
        self.suiteName = suiteName
    }
    
    var mainAppActivityStateSnapshot: MainAppActivityStateSnapshot {
        get {
            guard let store = TrackedUserDefaults(suiteName: suiteName) else {
                return .default
            }
            
            let snapshot: MainAppActivityStateSnapshot? = store[Self.mainAppActivityStateSnapshotKey]
            return snapshot ?? .default
        }
        nonmutating set {
            guard let store = TrackedUserDefaults(suiteName: suiteName) else {
                return
            }
            
            store[Self.mainAppActivityStateSnapshotKey] = newValue
        }
    }
    
    func updateMainAppActivityState(_ state: MainAppActivityState,
                                    systemUptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        mainAppActivityStateSnapshot = MainAppActivityStateSnapshot(state: state, lastUpdatedSystemUptime: systemUptime)
    }
}
