//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum DeveloperOptionsScreenViewModelAction {
    case clearCache
}

struct DeveloperOptionsScreenViewState: BindableState {
    let elementCallBaseURL: URL
    let isUsingNativeSlidingSync: Bool
    var bindings: DeveloperOptionsScreenViewStateBindings
    
    var slidingSyncFooter: String {
        "The method used to configure sliding sync when signing in. Changing this setting has no effect until you sign out.\n\nYour current session is using \(isUsingNativeSlidingSync ? "native sliding sync." : "a sliding sync proxy.")"
    }
}

// periphery: ignore - subscripts are seen as false positive
@dynamicMemberLookup
struct DeveloperOptionsScreenViewStateBindings {
    private let developerOptions: DeveloperOptionsProtocol

    init(developerOptions: DeveloperOptionsProtocol) {
        self.developerOptions = developerOptions
    }

    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<DeveloperOptionsProtocol, Setting>) -> Setting {
        get { developerOptions[keyPath: keyPath] }
        set { developerOptions[keyPath: keyPath] = newValue }
    }
}

enum DeveloperOptionsScreenViewAction {
    case clearCache
}

protocol DeveloperOptionsProtocol: AnyObject {
    var logLevel: TracingConfiguration.LogLevel { get set }
    var slidingSyncDiscovery: AppSettings.SlidingSyncDiscovery { get set }
    var hideUnreadMessagesBadge: Bool { get set }
    var elementCallBaseURLOverride: URL? { get set }
    var fuzzyRoomListSearchEnabled: Bool { get set }
    var pinningEnabled: Bool { get set }
    var invisibleCryptoEnabled: Bool { get set }
}

extension AppSettings: DeveloperOptionsProtocol { }
