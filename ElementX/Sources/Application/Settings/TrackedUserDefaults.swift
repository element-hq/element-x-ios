//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class TrackedUserDefaults: UserDefaults, UserDefaultsProtocol {
    private let lock = NSLock()
    
    private nonisolated(unsafe) var _trackedSuites: [String] = []
    private(set) var trackedSuites: [String] {
        get { lock.withLock { _trackedSuites } }
        set { lock.withLock { _trackedSuites = newValue } }
    }
    
    override init?(suiteName suitename: String?) {
        if let suitename {
            lock.lock()
            _trackedSuites = [suitename]
            lock.unlock()
        }
        
        super.init(suiteName: suitename)
    }
    
    override func addSuite(named suiteName: String) {
        trackedSuites.append(suiteName)
        super.addSuite(named: suiteName)
    }
    
    override func removeSuite(named suiteName: String) {
        trackedSuites.removeAll { $0 == suiteName }
        super.removeSuite(named: suiteName)
    }
    
    func resetRegisteredDomains() {
        lock.withLock {
            for suite in _trackedSuites {
                removePersistentDomain(forName: suite)
            }
        }
    }
    
    func reset() {
        resetRegisteredDomains()
    }
}
