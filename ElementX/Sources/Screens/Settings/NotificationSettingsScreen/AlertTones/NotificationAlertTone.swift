//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a notification alert tone and its backing audio file location.
struct NotificationAlertTone: Hashable, Comparable, Codable {
    private static let systemLocation = {
        let systemRoot: URL
        if let simulatorRoot = ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] {
            systemRoot = URL(filePath: simulatorRoot)
        } else {
            systemRoot = URL(filePath: "/")
        }
        return systemRoot.appending(components: "System", "Library", "Audio", "UISounds", directoryHint: .isDirectory)
    }()

    /// Directory where user-imported custom tones are stored.
    static let libraryLocation = URL.libraryDirectory.appending(components: "Sounds", "AvailableSounds", directoryHint: .isDirectory)
    private static let bundledLocation: URL = {
        guard let url = Bundle.app.resourceURL else {
            fatalError("The app is seriously corrupt if resourceURL is missing.")
        }
        return url
    }()

    /// Filename of the active tone file used by the notification service.
    static let selectedToneFilename = "currentAlert.caf"
    /// File URL of the active tone copied/linked for use by the system.
    static let selectedToneLocation = libraryLocation.deletingLastPathComponent().appending(component: selectedToneFilename)

    /// Display name for the tone, falling back to the filename stem.
    var label: String {
        labelOverride ?? location.deletingPathExtension().lastPathComponent
    }

    private let labelOverride: String?
    private let storageLocationRoot: StorageLocation
    private let relativePath: [String]
    /// Resolved absolute file URL for the audio file.
    var location: URL {
        let root: URL
        switch storageLocationRoot {
        case .system:
            root = Self.systemLocation
        case .appBundle:
            root = Self.bundledLocation
        case .appLibrary:
            root = Self.libraryLocation
        }

        return relativePath.reduce(root) {
            $0.appending(component: $1)
        }
    }

    /// The audio filename including its extension.
    var filename: String {
        location.lastPathComponent
    }

    /// - Parameters:
    ///   - labelOverride: Optional custom display name. If `nil`, the filename stem is used.
    ///   - storageLocationRoot: Where the file lives (system, bundle, or library).
    ///   - relativePath: Path components relative to the storage root, e.g. `["New", "Bloom.caf"]`.
    init(labelOverride: String?, storageLocationRoot: StorageLocation, relativePath: [String]) {
        self.labelOverride = labelOverride
        self.storageLocationRoot = storageLocationRoot
        self.relativePath = relativePath
    }

    /// Indicates which storage root backs the tone's audio file.
    enum StorageLocation: Codable, Hashable {
        /// The device's system sounds directory.
        case system
        /// The app's main bundle resources.
        case appBundle
        /// The app's Library directory (user-imported tones).
        case appLibrary
    }

    /// Creates a tone backed by a file in the system sounds directory.
    static func createSystemSound(label: String?, filename: String, systemSoundsSubdirectory: [String] = []) -> NotificationAlertTone {
        NotificationAlertTone(labelOverride: label, storageLocationRoot: .system, relativePath: systemSoundsSubdirectory + [filename])
    }

    /// Creates a tone backed by a file in the app bundle.
    static func createBundledSound(label: String?, filename: String) -> NotificationAlertTone {
        NotificationAlertTone(labelOverride: label, storageLocationRoot: .appBundle, relativePath: [filename])
    }

    /// Creates a tone backed by a user-imported file in the app library.
    static func createCustomUserSound(filename: String) -> NotificationAlertTone {
        NotificationAlertTone(labelOverride: nil, storageLocationRoot: .appLibrary, relativePath: [filename])
    }

    #if IS_MAIN_APP // localization is only available in the main app
    /// The default Element X bundled message tone.
    static let defaultElementXMessageTone: Self = .createBundledSound(label: UntranslatedL10n.screenNotificationSettingsSoundElementDefault,
                                                                      filename: "message.caf")

    /// Pre-defined iOS system tones available for selection, sorted by name.
    static let defaultSystemAlerts: [Self] = [
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemTriTone,
                           filename: "sms-received1.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemChime,
                           filename: "sms-received2.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemGlass,
                           filename: "sms-received3.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemHorn,
                           filename: "sms-received4.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemBell,
                           filename: "sms-received5.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemElectronic,
                           filename: "sms-received6.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemAlert,
                           filename: "alarm.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemBloom,
                           filename: "Bloom.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemCalypso,
                           filename: "Calypso.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemAnticipate,
                           filename: "Anticipate.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemChooChoo,
                           filename: "Choo_Choo.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemDescent,
                           filename: "Descent.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemFanfare,
                           filename: "Fanfare.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemLadder,
                           filename: "Ladder.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemMinuet,
                           filename: "Minuet.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemNewsFlash,
                           filename: "News_Flash.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemNoir,
                           filename: "Noir.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemSherwoodForest,
                           filename: "Sherwood_Forest.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemSpell,
                           filename: "Spell.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemSuspense,
                           filename: "Suspense.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemTelegraph,
                           filename: "Telegraph.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemTiptoes,
                           filename: "Tiptoes.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemTypewriters,
                           filename: "Typewriters.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemUpdate,
                           filename: "Update.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemSwish,
                           filename: "Swish.caf"),
        .createSystemSound(label: UntranslatedL10n.screenNotificationSettingsSoundSystemTweet,
                           filename: "tweet_sent.caf")
    ]
    .compactMap { (alertTone: NotificationAlertTone) -> NotificationAlertTone? in
        guard (try? alertTone.location.checkResourceIsReachable()) == true else {
            return nil
        }
        return alertTone
    }
    .sorted()
    
    /// Element X bundled tones available for selection, sorted by name.
    static let defaultElementXAlerts: [Self] = [
        defaultElementXMessageTone,
        .createBundledSound(label: UntranslatedL10n.screenNotificationSettingsSoundElementFade,
                            filename: "sound_01.caf")
    ].sorted()

    /// All default tones (system + Element X), sorted by name.
    static let allDefaultAlerts: [Self] = (defaultSystemAlerts + defaultElementXAlerts).sorted()
    #endif

    static func < (lhs: NotificationAlertTone, rhs: NotificationAlertTone) -> Bool {
        lhs.label < rhs.label
    }
}
