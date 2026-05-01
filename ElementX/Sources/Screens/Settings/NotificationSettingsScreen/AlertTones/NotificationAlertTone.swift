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
    static let defaultElementXMessageTone: Self = .createBundledSound(label: UntranslatedL10n.messageToneElementxDefault,
                                                                      filename: "message.caf")

    /// Pre-defined iOS system tones available for selection, sorted by name.
    static let defaultSystemAlerts: [Self] = [
        .createSystemSound(label: UntranslatedL10n.messageToneSystemTriTone,
                           filename: "sms-received1.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemChime,
                           filename: "sms-received2.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemGlass,
                           filename: "sms-received3.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemHorn,
                           filename: "sms-received4.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemBell,
                           filename: "sms-received5.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemElectronic,
                           filename: "sms-received6.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemAlert,
                           filename: "alarm.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemBloom,
                           filename: "Bloom.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemCalypso,
                           filename: "Calypso.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemAnticipate,
                           filename: "Anticipate.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemChooChoo,
                           filename: "Choo_Choo.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemDescent,
                           filename: "Descent.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemFanfare,
                           filename: "Fanfare.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemLadder,
                           filename: "Ladder.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemMinuet,
                           filename: "Minuet.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemNewsFlash,
                           filename: "News_Flash.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemNoir,
                           filename: "Noir.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemSherwoodForest,
                           filename: "Sherwood_Forest.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemSpell,
                           filename: "Spell.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemSuspense,
                           filename: "Suspense.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemTelegraph,
                           filename: "Telegraph.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemTiptoes,
                           filename: "Tiptoes.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemTypewriters,
                           filename: "Typewriters.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemUpdate,
                           filename: "Update.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemSwish,
                           filename: "Swish.caf"),
        .createSystemSound(label: UntranslatedL10n.messageToneSystemTweet,
                           filename: "tweet_sent.caf")
    ].sorted()

    /// Element X bundled tones available for selection, sorted by name.
    static let defaultElementXAlerts: [Self] = [
        defaultElementXMessageTone,
        .createBundledSound(label: UntranslatedL10n.messageToneElementxTripleSine,
                            filename: "triple_sin.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxProDefault,
                            filename: "sound_01.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxWisp,
                            filename: "wisp.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxWarble,
                            filename: "warble.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxTheAughts,
                            filename: "the_aughts.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxTrill,
                            filename: "trill.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxSineF,
                            filename: "sine_f.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxSingingBowl,
                            filename: "singing_bowl.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxGlassKnock,
                            filename: "glass_knock.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxNudge,
                            filename: "nudge.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxAdrift,
                            filename: "adrift.caf"),
        .createBundledSound(label: UntranslatedL10n.messageToneElementxFlick,
                            filename: "flick.caf")
    ].sorted()

    /// All default tones (system + Element X), sorted by name.
    static let allDefaultAlerts: [Self] = (defaultSystemAlerts + defaultElementXAlerts).sorted()
    #endif

    static func < (lhs: NotificationAlertTone, rhs: NotificationAlertTone) -> Bool {
        lhs.label < rhs.label
    }
}
