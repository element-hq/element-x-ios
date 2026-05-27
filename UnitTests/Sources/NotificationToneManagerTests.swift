//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

/// These tests exercise `NotificationToneManager` against the real app sandbox filesystem.
/// Because all tests share a single `libraryLocation` directory on disk, they are inherently
/// incapable of running in parallel — files written by one test would corrupt the state of
/// another. This project runs test in serial regardless, but this is just to document this is a specific case
/// relying on that behavior.
struct NotificationToneManagerTests {
    private let manager: NotificationToneManager
    
    init() {
        manager = NotificationToneManager(appSettings: .volatile())
    }
    
    // MARK: - Deletion
    
    @Test
    func deletingSystemToneThrowsNotACustomTone() {
        // Given a system tone (lives outside the library directory)
        let tone = NotificationTone.createSystemSound(label: nil, filename: "alarm.caf")
        
        // When deletion is attempted
        // Then it throws because only library tones may be deleted
        let error = #expect(throws: NotificationToneManager.ManagerError.self) {
            try manager.deleteCustomTone(tone)
        }
        
        #expect(error == .notACustomTone)
    }
    
    @Test
    func deletingBundledToneThrowsNotACustomTone() {
        // Given a bundled app tone (lives outside the library directory)
        let tone = NotificationTone.createBundledSound(label: nil, filename: "message.caf")
        
        // When deletion is attempted
        // Then it throws because only library tones may be deleted
        let error = #expect(throws: NotificationToneManager.ManagerError.self) {
            try manager.deleteCustomTone(tone)
        }
        
        #expect(error == .notACustomTone)
    }
    
    // MARK: - Custom Tone Listing
    
    @Test
    func customTonesFiltersToCAFOnly() throws {
        // Given both CAF and non-CAF files written to the library directory
        let cafURL = NotificationToneManager.libraryLocation.appending(component: "\(UUID().uuidString).caf")
        let mp3URL = NotificationToneManager.libraryLocation.appending(component: "\(UUID().uuidString).mp3")
        defer {
            try? FileManager.default.removeItem(at: cafURL)
            try? FileManager.default.removeItem(at: mp3URL)
        }
        try Data().write(to: cafURL)
        try Data().write(to: mp3URL)
        
        // When fetching the list of custom tones
        let tones = manager.customTones()
        
        // Then only the CAF file is included
        #expect(tones.contains { $0.filename == cafURL.lastPathComponent })
        #expect(!tones.contains { $0.filename == mp3URL.lastPathComponent })
    }
    
    // MARK: - Import
    
    @Test
    func addingDuplicateToneThrowsFileAlreadyExists() async throws {
        // Given a CAF file that has already been imported into the library
        let sourceURL = URL.temporaryDirectory.appending(component: "\(UUID().uuidString).caf")
        let importedURL = NotificationToneManager.libraryLocation
            .appending(component: sourceURL.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("caf")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: importedURL)
        }
        try Data().write(to: sourceURL)
        try await manager.addNewToneToLibrary(from: sourceURL)
        
        // When importing the same file a second time
        // Then it throws ConversionError (specifically fileAlreadyExists)
        await #expect(throws: NotificationToneManager.ManagerError.self) {
            try await manager.addNewToneToLibrary(from: sourceURL)
        }
    }
}
