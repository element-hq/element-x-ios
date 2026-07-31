//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

/// Manages the tracking, removal, and autocomplete matchin of previous servers in AppSettings.
/// Servers are sorted by most recently used.
class HomeserverHistoryManager {
    let appSettings: AppSettings
    
    /// cache with confirmed lowercase servers to avoid having to lowercase the entire list on every keystroke
    private var cachedServers: [String] = []
    var servers: [String] {
        cachedServers
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        
        appSettings
            .previousServersPublisher
            .sink { [weak self] _ in
                self?.updateCachedServers()
            }
            .store(in: &cancellables)
    }
    
    /// Tracks the given server in AppSettings's `previousServers`. The server is asserted
    /// unique and placed at the beginning of the list, such that the most recent connected server is at the front.
    func addServerToList(_ server: String) {
        MXLog.info("Tracking server in previous servers: \(server)")
        
        let lowercaseServer = server.lowercased()
        var newList = _removeServerFromList(lowercaseServer) // don't trigger a publisher update
        newList.insert(lowercaseServer, at: 0)
        appSettings.previousServers = newList
    }
    
    /// Removes `server` from the tracking history of `AppSettings.previousServers`
    func removeServerFromList(_ server: String) {
        appSettings.previousServers = _removeServerFromList(server)
    }
    
    private func _removeServerFromList(_ server: String) -> [String] {
        let lowercaseServer = server.lowercased()
        var newList = appSettings.previousServers
        newList.removeAll { $0.lowercased() == lowercaseServer }
        return newList
    }
    
    /// Retrieves the most recent server matching the given prefix, if any
    func server(matchingPrefix prefix: String) -> String? {
        let lowercasedPrefix = prefix.lowercased()
        return servers.first { $0.hasPrefix(lowercasedPrefix) }
    }
    
    /// Retrieves all servers from AppSettings, previous and pre-provided and stores them in memory
    /// in all lowercase. This is the list that matches are made against.
    private func updateCachedServers() {
        let previous = appSettings.previousServers.map { $0.lowercased() }
        let defaultProviders = appSettings.accountProviders.map { $0.lowercased() }
        
        cachedServers = previous + defaultProviders
    }
}
