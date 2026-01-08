//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DeveloperOptionsScreenViewModelAction {
    case clearCache
}

struct DeveloperOptionsScreenViewState: BindableState {
    let elementCallBaseURL: URL
    let appHooks: AppHooks
    var storeSizes: [StoreSize]?
    var bindings: DeveloperOptionsScreenViewStateBindings
    
    struct StoreSize: Identifiable {
        let name: String
        let size: String
        
        var id: String {
            name + size
        }
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
    var logLevel: LogLevel { get set }
    var traceLogPacks: Set<TraceLogPack> { get set }
    
    var enableOnlySignedDeviceIsolationMode: Bool { get set }
    var enableKeyShareOnInvite: Bool { get set }
    var hideQuietNotificationAlerts: Bool { get set }
    var focusEventOnNotificationTap: Bool { get set }
    
    var hideUnreadMessagesBadge: Bool { get set }
    var elementCallBaseURLOverride: URL? { get set }
    
    var publicSearchEnabled: Bool { get set }
    var fuzzyRoomListSearchEnabled: Bool { get set }
    var lowPriorityFilterEnabled: Bool { get set }
    var knockingEnabled: Bool { get set }
    
    var linkPreviewsEnabled: Bool { get set }
    
    var linkNewDeviceEnabled: Bool { get set }
    
    var spaceSettingsEnabled: Bool { get set }
    var createSpaceEnabled: Bool { get set }
}

extension AppSettings: DeveloperOptionsProtocol { }
