//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// A CoordinatorProtocol wrapper and type erasing component that allows
/// dynamically presenting arbitrary screens
@MainActor
class NavigationModule: Identifiable, Hashable {
    let id = UUID()
    
    /// The NavigationStack has a tendency to hold on to path items for longer than needed. We work around that by manually nilling the coordinator
    /// when a NavigationModule is dismissed, reason why this is an optional property
    /// As the NavigationModule is just a wrapper multiple instances of it continuing living is of no consequence
    /// https://stackoverflow.com/questions/73885353/found-a-strange-behaviour-of-state-when-combined-to-the-new-navigation-stack/
    var coordinator: (any CoordinatorProtocol)?
    var dismissalCallback: (() -> Void)?
    
    init(_ coordinator: any CoordinatorProtocol, dismissalCallback: (() -> Void)? = nil) {
        self.coordinator = coordinator
        self.dismissalCallback = dismissalCallback
    }
    
    func tearDown() {
        coordinator?.stop()
        coordinator = nil
        
        let callback = dismissalCallback
        dismissalCallback = nil
        callback?()
    }
    
    nonisolated static func == (lhs: NavigationModule, rhs: NavigationModule) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
