//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

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

    static let libraryLocation = URL.libraryDirectory.appending(components: "Sounds", "AvailableSounds", directoryHint: .isDirectory)
    private static let bundledLocation: URL = {
        guard let url = Bundle.app.resourceURL else {
            fatalError("The app is seriously corrupt if resourceURL is missing.")
        }
        return url
    }()

    static let selectedToneFilename = "currentAlert.caf"
    static let selectedToneLocation = libraryLocation.deletingLastPathComponent().appending(component: selectedToneFilename)

    var label: String {
        labelOverride ?? location.deletingPathExtension().lastPathComponent
    }

    private let labelOverride: String?
    let location: URL
    var filename: String {
        location.lastPathComponent
    }

    init(labelOverride: String?, location: URL) {
        self.labelOverride = labelOverride
        self.location = location
    }

    enum CodingKeys: CodingKey {
        case labelOverride
        case location
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let bookmarkData = try container.decode(Data.self, forKey: .location)
        var stale = false
        let location = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &stale)
        let labelOverride = try container.decodeIfPresent(String.self, forKey: .labelOverride)

        self.init(labelOverride: labelOverride, location: location)
    }

    func encode(to encoder: any Encoder) throws {
        let bookmarkData = try location.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(bookmarkData, forKey: .location)
        try container.encodeIfPresent(labelOverride, forKey: .labelOverride)
    }

    static func createSystemSound(label: String?, filename: String, systemSoundsSubdirectory: [String]? = nil) -> NotificationAlertTone {
        var systemLocation = Self.systemLocation
        for subdirectory in systemSoundsSubdirectory ?? [] {
            systemLocation.append(component: subdirectory)
        }

        return NotificationAlertTone(labelOverride: label, location: systemLocation.appending(component: filename))
    }

    static func createBundledSound(label: String?, filename: String) -> NotificationAlertTone {
        NotificationAlertTone(labelOverride: label, location: bundledLocation.appending(component: filename))
    }

    static func createCustomUserSound(filename: String) -> NotificationAlertTone {
        NotificationAlertTone(labelOverride: nil, location: libraryLocation.appending(component: filename))
    }

    #if IS_MAIN_APP // localization is only available in the main app
    static let defaultElementXMessageTone: Self = .createBundledSound(label: UntranslatedL10n.messageToneElementxDefault,
                                                                      filename: "message.caf")

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

    static let defaultElementXAlerts: [Self] = {
        let base: [Self] = [
            defaultElementXMessageTone,
            .createBundledSound(label: UntranslatedL10n.messageToneTripleSin,
                                filename: "triple_sin.caf")
        ]

        let proToneURL = Self.bundledLocation.appending(component: "sound_01.caf")
        guard (try? proToneURL.checkResourceIsReachable()) == true else { return base }

        let proTone: Self = .createBundledSound(label: UntranslatedL10n.messageToneElementxProDefault,
                                                filename: "sound_01.caf")
        return base + [proTone]
    }().sorted()

    static let allDefaultAlerts: [Self] = (defaultSystemAlerts + defaultElementXAlerts).sorted()
    #endif

    static func < (lhs: NotificationAlertTone, rhs: NotificationAlertTone) -> Bool {
        lhs.label < rhs.label
    }
}
