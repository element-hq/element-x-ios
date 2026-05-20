//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a notification alert tone and its backing audio file location.
struct NotificationTone: Hashable, Comparable, Codable {
    /// Display name for the tone, falling back to the filename stem.
    var label: String {
        labelOverride ?? URL(filePath: "/\(relativePath.last, default: "")").deletingPathExtension().lastPathComponent
    }

    private let labelOverride: String?
    let storageLocationRoot: StorageLocation
    let relativePath: [String]

    /// The audio filename including its extension.
    var filename: String {
        relativePath.last ?? ""
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
    static func createSystemSound(label: String?, filename: String, systemSoundsSubdirectory: [String] = []) -> NotificationTone {
        NotificationTone(labelOverride: label, storageLocationRoot: .system, relativePath: systemSoundsSubdirectory + [filename])
    }

    /// Creates a tone backed by a file in the app bundle.
    static func createBundledSound(label: String?, filename: String) -> NotificationTone {
        NotificationTone(labelOverride: label, storageLocationRoot: .appBundle, relativePath: [filename])
    }

    /// Creates a tone backed by a user-imported file in the app library.
    static func createCustomUserSound(filename: String) -> NotificationTone {
        NotificationTone(labelOverride: nil, storageLocationRoot: .appLibrary, relativePath: [filename])
    }

    static func < (lhs: NotificationTone, rhs: NotificationTone) -> Bool {
        lhs.label < rhs.label
    }
}
