//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum DeveloperOptionsScreenViewModelAction {
    case clearCache
}

struct DeveloperOptionsScreenViewState: BindableState {
    let appHooks: AppHooks
    var storeSizes: [StoreSize]?
    let shouldShowClearCache: Bool
    let isSignedIn: Bool
    
    var bindings: DeveloperOptionsScreenViewStateBindings
    
    struct StoreSize: Identifiable {
        let name: String
        let size: String
        
        var id: String {
            name + size
        }
    }
}

struct DeveloperOptionsScreenViewStateBindings {
    private let settings: DeveloperOptionsScreenSettings
    
    init(settings: DeveloperOptionsScreenSettings) {
        self.settings = settings
    }
    
    var logLevel: LogLevel {
        get { settings.logLevel }
        set { settings.logLevel = newValue }
    }
    
    var traceLogPacks: Set<TraceLogPack> {
        get { settings.traceLogPacks }
        set { settings.traceLogPacks = newValue }
    }
    
    var enableOnlySignedDeviceIsolationMode: Bool {
        get { settings.enableOnlySignedDeviceIsolationMode }
        set { settings.enableOnlySignedDeviceIsolationMode = newValue }
    }
    
    var hideQuietNotificationAlerts: Bool {
        get { settings.hideQuietNotificationAlerts }
        set { settings.hideQuietNotificationAlerts = newValue }
    }
    
    var focusEventOnNotificationTap: Bool {
        get { settings.focusEventOnNotificationTap }
        set { settings.focusEventOnNotificationTap = newValue }
    }
    
    var elementCallBaseURLOverride: URL? {
        get { settings.elementCallBaseURLOverride }
        set { settings.elementCallBaseURLOverride = newValue }
    }
    
    var fuzzyRoomListSearchEnabled: Bool {
        get { settings.fuzzyRoomListSearchEnabled }
        set { settings.fuzzyRoomListSearchEnabled = newValue }
    }
    
    var lowPriorityFilterEnabled: Bool {
        get { settings.lowPriorityFilterEnabled }
        set { settings.lowPriorityFilterEnabled = newValue }
    }
    
    var mentionsFilterEnabled: Bool {
        get { settings.mentionsFilterEnabled }
        set { settings.mentionsFilterEnabled = newValue }
    }
    
    var linkPreviewsEnabled: Bool {
        get { settings.linkPreviewsEnabled }
        set { settings.linkPreviewsEnabled = newValue }
    }
    
    var jumpToReadMarkerEnabled: Bool {
        get { settings.jumpToReadMarkerEnabled }
        set { settings.jumpToReadMarkerEnabled = newValue }
    }
    
    var messageMultiSelectEnabled: Bool {
        get { settings.messageMultiSelectEnabled }
        set { settings.messageMultiSelectEnabled = newValue }
    }
    
    var linkNewDeviceEnabled: Bool {
        get { settings.linkNewDeviceEnabled }
        set { settings.linkNewDeviceEnabled = newValue }
    }
    
    var globalSearchEnabled: Bool {
        get { settings.globalSearchEnabled }
        set { settings.globalSearchEnabled = newValue }
    }
    
    var multiAccountEnabled: Bool {
        get { settings.multiAccountEnabled }
        set { settings.multiAccountEnabled = newValue }
    }
    
    var multiAccountEnabledPublisher: AnyPublisher<Bool, Never> {
        settings.multiAccountEnabledPublisher
    }
    
    var hasSeenMultiAccountAnnouncement: Bool {
        get { settings.hasSeenMultiAccountAnnouncement }
        set { settings.hasSeenMultiAccountAnnouncement = newValue }
    }
    
    var nativeCallEnabled: Bool {
        get { settings.nativeCallEnabled }
        set { settings.nativeCallEnabled = newValue }
    }
}

/// Shared access to app-specific settings, either via an `AppSettings` instance, or a user-specific `UserSettings` instance.
///
/// In the future this could also vend a (scoped) `account` object that takes `AccountSettings` key paths if we ever need to
/// conditionalise some settings.
@dynamicMemberLookup
class DeveloperOptionsScreenSettings {
    enum Source {
        case app(AppSettings)
        case user(UserSettings)
    }
    
    let source: Source
    
    init(source: Source) {
        self.source = source
    }
    
    subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<AppSettings, Value>) -> Value {
        get {
            switch source {
            case .app(let appSettings): appSettings[keyPath: keyPath]
            case .user(let userSettings): userSettings[dynamicMember: keyPath]
            }
        }
        set {
            switch source {
            case .app(let appSettings): appSettings[keyPath: keyPath] = newValue
            case .user(let userSettings): userSettings[dynamicMember: keyPath] = newValue
            }
        }
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<AppSettings, Value>) -> Value {
        switch source {
        case .app(let appSettings): appSettings[keyPath: keyPath]
        case .user(let userSettings): userSettings[dynamicMember: keyPath]
        }
    }
}

enum DeveloperOptionsScreenViewAction {
    case clearCache
    case markAllRoomsAsRead
}
