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
        return systemRoot.appending(components: "System", "Library", "Audio", "UISounds")
    }()

    private static let libraryLocation = URL.libraryDirectory.appending(components: "Sounds", "AvailableSounds")
    private static let bundledLocation: URL = {
        guard let url = Bundle.app.resourceURL else {
            fatalError("The app is seriously corrupt if resourceURL is missing.")
        }
        return url
    }()

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
    static let defaultElementXMessageTone: Self = .createBundledSound(label: "Default Message",
                                                                      filename: "message.caf")

    static let defaultSystemAlerts: [Self] = [
        .createSystemSound(label: "Tri-tone",
                           filename: "sms-received1.caf"),
        .createSystemSound(label: "Chime",
                           filename: "sms-received2.caf"),
        .createSystemSound(label: "Glass",
                           filename: "sms-received3.caf"),
        .createSystemSound(label: "Horn",
                           filename: "sms-received4.caf"),
        .createSystemSound(label: "Bell",
                           filename: "sms-received5.caf"),
        .createSystemSound(label: "Electronic",
                           filename: "sms-received6.caf"),
        .createSystemSound(label: "Alert",
                           filename: "alarm.caf"),
        .createSystemSound(label: "Bloom",
                           filename: "Bloom.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Calypso",
                           filename: "Calypso.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Anticipate",
                           filename: "Anticipate.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Choo Choo",
                           filename: "Choo_Choo.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Descent",
                           filename: "Descent.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Fanfare",
                           filename: "Fanfare.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Ladder",
                           filename: "Ladder.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Minuet",
                           filename: "Minuet.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "News Flash",
                           filename: "News_Flash.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Noir",
                           filename: "Noir.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Sherwood Forest",
                           filename: "Sherwood_Forest.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Spell",
                           filename: "Spell.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Suspense",
                           filename: "Suspense.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Telegraph",
                           filename: "Telegraph.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Tiptoes",
                           filename: "Tiptoes.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Typewriters",
                           filename: "Typewriters.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Update",
                           filename: "Update.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: "Swish",
                           filename: "Swish.caf"),
        .createSystemSound(label: "Tweet",
                           filename: "tweet_sent.caf")
    ].sorted()

    static let defaultElementXAlerts: [Self] = [
        defaultElementXMessageTone,
        .createBundledSound(label: "Triple Sin",
                            filename: "triple_sin.caf")
    ].sorted()
    #endif

    static func < (lhs: NotificationAlertTone, rhs: NotificationAlertTone) -> Bool {
        lhs.label < rhs.label
    }
}
