//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@preconcurrency import AVFoundation
import Foundation
import UniformTypeIdentifiers

/// Manages notification tone selection, import, conversion, and deletion.
nonisolated struct NotificationToneManager: NotificationToneManagerProtocol {
    @globalActor
    actor ConversionActor {
        static let shared = ConversionActor()
    }
    
    enum ManagerError: Error, Equatable {
        /// The tone's file is not inside the user library directory and cannot be deleted.
        case notACustomTone
        
        /// The source file could not be accessed due to sandbox restrictions.
        case couldNotAccessSandboxedResource
        
        /// A tone with the same filename already exists in the library.
        case fileAlreadyExists
        /// An `AVAudioPCMBuffer` could not be allocated.
        case bufferCreationFailed
    }
    
    private let userSettings: UserSettings
    
    /// The default Element X bundled message tone.
    static let defaultElementXMessageTone: NotificationTone = .createBundledSound(label: L10n.screenNotificationSettingsSoundElementDefault,
                                                                                  filename: "message.caf")
    
    /// All default tones (system + Element X), sorted by name.
    static let allDefaultAlerts: [NotificationTone] = (defaultSystemAlerts + defaultElementXAlerts).sorted()
    
    /// The name the notification service uses to find the tone's file in the app bundle or Library/Sounds.
    ///
    /// Note: Names with a subdirectory aren't documented for `UNNotificationSound(named:)` but do work.
    static func soundName(for tone: NotificationTone) -> String {
        switch tone.storageLocationRoot {
        case .appBundle:
            tone.filename
        case .appLibrary:
            "\(URL.customTonesDirectory.lastPathComponent)/\(tone.filename)"
        case .system:
            "\(URL.systemTonesDirectory.lastPathComponent)/\(tone.filename)"
        }
    }
    
    /// Copies a system tone into Library/Sounds, as the system sounds directory isn't searched for notification sounds.
    static func copySystemToneIfNeeded(_ tone: NotificationTone) throws {
        guard tone.storageLocationRoot == .system else { return }
        
        let copyLocation = URL.systemTonesDirectory.appending(component: tone.filename)
        guard (try? copyLocation.checkResourceIsReachable()) != true else { return }
        
        try FileManager.default.createDirectory(at: URL.systemTonesDirectory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: toneLocation(for: tone), to: copyLocation)
    }
    
    /// Creates the manager and ensures required library directories exist.
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
        
        do {
            try FileManager.default.createDirectory(at: URL.customTonesDirectory, withIntermediateDirectories: true)
        } catch {
            // Don't crash on a recoverable file system error. The underlying problem (directory creation
            // failing on launch, e.g. a background launch before the container is writable) is acknowledged
            // and will be treated separately.
            MXLog.error("Failed setting up tone manager directories: \(error)")
        }
    }
    
    /// Sets the given tone as the active notification alert tone.
    func setSelectedTone(_ alertTone: NotificationTone) throws -> URL {
        try Self.copySystemToneIfNeeded(alertTone)
        userSettings.account.selectedNotificationTone = alertTone
        return Self.toneLocation(for: alertTone)
    }
    
    /// Returns all user-imported CAF tones from the library directory, sorted by name.
    func customTones() -> [NotificationTone] {
        let availableFiles = try? FileManager
            .default
            .contentsOfDirectory(at: URL.customTonesDirectory, includingPropertiesForKeys: nil)
        
        return (availableFiles ?? [])
            .compactMap {
                let pathExtension = $0.pathExtension
                guard UTType(filenameExtension: pathExtension) == UTType("com.apple.coreaudio-format") else { return nil }
                
                return .createCustomUserSound(filename: $0.lastPathComponent)
            }
            .sorted()
    }
    
    /// Imports an audio file into the tone library, converting to CAF if the source is not already CAF.
    /// - Returns: The URL of the imported file in the library.
    @ConversionActor
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outputURL = URL.customTonesDirectory.appending(component: baseName).appendingPathExtension("caf")
        
        guard (try? outputURL.checkResourceIsReachable()) != true else {
            throw ManagerError.fileAlreadyExists
        }
        
        if sourceURL.pathExtension.lowercased() == "caf" {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        } else {
            try convertToCAF(from: sourceURL, to: outputURL)
        }
        
        return outputURL
    }
    
    /// Removes a user-imported tone from the library.
    /// - Throws: `DeletionError.notACustomTone` if the tone is not stored in the library directory.
    func deleteCustomTone(_ alertTone: NotificationTone) throws {
        let toneLocation = Self.toneLocation(for: alertTone)
        guard toneLocation.deletingLastPathComponent() == URL.customTonesDirectory else {
            throw ManagerError.notACustomTone
        }
        
        try FileManager.default.removeItem(at: toneLocation)
    }
    
    // MARK: - Private
    
    @ConversionActor
    private func convertToCAF(from sourceURL: URL, to destURL: URL) throws {
        MXLog.info("Converting \(sourceURL.path(percentEncoded: false)) to caf")
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sourceFile.fileFormat.sampleRate,
            AVNumberOfChannelsKey: sourceFile.fileFormat.channelCount
        ]
        
        let tempURL = URL.temporaryDirectory.appending(component: destURL.lastPathComponent)
        
        let destTempFile = try AVAudioFile(forWriting: tempURL, settings: outputSettings)
        
        let frameCount: AVAudioFrameCount = 4096
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: sourceFile.processingFormat, frameCapacity: frameCount) else {
            MXLog.error("Error creating pcm conversion buffer: \(sourceFile.processingFormat) \(frameCount)")
            throw ManagerError.bufferCreationFailed
        }
        
        do {
            repeat {
                try sourceFile.read(into: pcmBuffer)
                
                guard pcmBuffer.frameLength > 0 else { break }
                
                try destTempFile.write(from: pcmBuffer)
            } while pcmBuffer.frameLength > 0 && sourceFile.framePosition < sourceFile.length
        } catch {
            let nsError = error as NSError
            guard
                // the framePosition < sourceFile.length SHOULD stop this from throwing, but as
                // a defensive fallback, this just means that it reached/read past EOF
                nsError.code == 0,
                nsError.domain == "Foundation._GenericObjCError"
            else { throw error }
        }
        destTempFile.close()
        
        try FileManager.default.moveItem(at: tempURL, to: destURL)
        MXLog.info("Converted \(sourceURL.path(percentEncoded: false)) to caf")
    }
    
    /// Pre-defined iOS system tones available for selection, sorted by name.
    private static let defaultSystemAlerts: [NotificationTone] = [
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTriToneIos,
                           filename: "sms-received1.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemChimeIos,
                           filename: "sms-received2.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemGlassIos,
                           filename: "sms-received3.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemHornIos,
                           filename: "sms-received4.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemBellIos,
                           filename: "sms-received5.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemElectronicIos,
                           filename: "sms-received6.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemAlertIos,
                           filename: "alarm.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemBloomIos,
                           filename: "Bloom.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemCalypsoIos,
                           filename: "Calypso.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemAnticipateIos,
                           filename: "Anticipate.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemChooChooIos,
                           filename: "Choo_Choo.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemDescentIos,
                           filename: "Descent.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemFanfareIos,
                           filename: "Fanfare.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemLadderIos,
                           filename: "Ladder.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemMinuetIos,
                           filename: "Minuet.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemNewsFlashIos,
                           filename: "News_Flash.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemNoirIos,
                           filename: "Noir.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSherwoodForestIos,
                           filename: "Sherwood_Forest.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSpellIos,
                           filename: "Spell.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSuspenseIos,
                           filename: "Suspense.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTelegraphIos,
                           filename: "Telegraph.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTiptoesIos,
                           filename: "Tiptoes.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTypewritersIos,
                           filename: "Typewriters.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemUpdateIos,
                           filename: "Update.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSwishIos,
                           filename: "Swish.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTweetIos,
                           filename: "tweet_sent.caf")
    ]
    .compactMap { (alertTone: NotificationTone) -> NotificationTone? in
        let toneLocation = toneLocation(for: alertTone)
        guard (try? toneLocation.checkResourceIsReachable()) == true else {
            return nil
        }
        return alertTone
    }
    .sorted()
    
    /// Element X bundled tones available for selection, sorted by name.
    private static let defaultElementXAlerts: [NotificationTone] = [
        defaultElementXMessageTone,
        .createBundledSound(label: L10n.screenNotificationSettingsSoundElementFade,
                            filename: "sound_01.caf")
    ].sorted()
    
    private static let systemLocation = URL.systemSoundsDirectory
    
    private static let bundledLocation: URL = {
        guard let url = Bundle.app.resourceURL else {
            fatalError("The app is seriously corrupt if resourceURL is missing.")
        }
        return url
    }()
    
    private static func toneLocation(for tone: NotificationTone) -> URL {
        let root: URL
        switch tone.storageLocationRoot {
        case .system:
            root = Self.systemLocation
        case .appBundle:
            root = Self.bundledLocation
        case .appLibrary:
            root = URL.customTonesDirectory
        }
        
        return tone.relativePath.reduce(root) {
            $0.appending(component: $1)
        }
    }
}
