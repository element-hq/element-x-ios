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
struct NotificationToneManager: NotificationToneManagerProtocol {
    @globalActor
    actor ConversionActor {
        static let shared = ConversionActor()
    }
    
    enum ManagerError: Error, Equatable {
        /// The tone's file is not inside the user library directory and cannot be deleted.
        case notACustomTone
        
        /// The source file could not be accessed due to sandbox restrictions.
        case couldNotAccessSandboxedResource
        
        /// `AVAudioConverter` could not be initialised for the given format pair.
        case converterSetupFailed
        /// A tone with the same filename already exists in the library.
        case fileAlreadyExists
        /// An `AVAudioPCMBuffer` could not be allocated.
        case bufferCreationFailed
    }
    
    private let appSettings: AppSettings
    
    /// The default Element X bundled message tone.
    static let defaultElementXMessageTone: NotificationTone = .createBundledSound(label: L10n.screenNotificationSettingsSoundElementDefault,
                                                                                  filename: "message.caf")
    
    /// All default tones (system + Element X), sorted by name.
    static let allDefaultAlerts: [NotificationTone] = (defaultSystemAlerts + defaultElementXAlerts).sorted()
    
    /// Filename of the active tone file used by the notification service.
    static let selectedToneFilename = "currentAlert.caf"
    
    /// Directory where user-imported custom tones are stored.
    static let libraryLocation = URL.libraryDirectory.appending(components: "Sounds", "AvailableSounds", directoryHint: .isDirectory)
    
    /// Creates the manager and ensures required library directories exist.
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        
        do {
            try FileManager.default.createDirectory(at: NotificationToneManager.libraryLocation, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: Self.selectedToneLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            fatalError("Catastrophic error setting up tone manager: \(error)")
        }
    }
    
    /// Sets the given tone as the active notification alert tone.
    ///
    /// Copies the tone's audio file to `selectedToneLocation` and persists the selection in app settings.
    func setSelectedTone(_ alertTone: NotificationTone) throws -> URL {
        do {
            try? FileManager.default.removeItem(at: Self.selectedToneLocation)
            let toneLocation = Self.toneLocation(for: alertTone)
            try FileManager.default.copyItem(at: toneLocation, to: Self.selectedToneLocation)
            appSettings.selectedNotificationTone = alertTone
            return Self.selectedToneLocation
        } catch {
            if (try? Self.selectedToneLocation.checkResourceIsReachable()) != true {
                // make sure the selected tone is reset if there's no custom tone present
                appSettings.selectedNotificationTone = nil
            }
            throw error
        }
    }
    
    /// Returns all user-imported CAF tones from the library directory, sorted by name.
    func customTones() -> [NotificationTone] {
        let availableFiles = try? FileManager
            .default
            .contentsOfDirectory(at: NotificationToneManager.libraryLocation, includingPropertiesForKeys: nil)
        
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
        let outputURL = NotificationToneManager.libraryLocation.appending(component: baseName).appendingPathExtension("caf")
        
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
        guard toneLocation.deletingLastPathComponent() == NotificationToneManager.libraryLocation else {
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

    /// File URL of the active tone copied/linked for use by the system.
    private static let selectedToneLocation = NotificationToneManager.libraryLocation.deletingLastPathComponent().appending(component: selectedToneFilename)

    /// Pre-defined iOS system tones available for selection, sorted by name.
    private static let defaultSystemAlerts: [NotificationTone] = [
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTriTone,
                           filename: "sms-received1.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemChime,
                           filename: "sms-received2.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemGlass,
                           filename: "sms-received3.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemHorn,
                           filename: "sms-received4.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemBell,
                           filename: "sms-received5.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemElectronic,
                           filename: "sms-received6.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemAlert,
                           filename: "alarm.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemBloom,
                           filename: "Bloom.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemCalypso,
                           filename: "Calypso.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemAnticipate,
                           filename: "Anticipate.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemChooChoo,
                           filename: "Choo_Choo.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemDescent,
                           filename: "Descent.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemFanfare,
                           filename: "Fanfare.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemLadder,
                           filename: "Ladder.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemMinuet,
                           filename: "Minuet.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemNewsFlash,
                           filename: "News_Flash.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemNoir,
                           filename: "Noir.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSherwoodForest,
                           filename: "Sherwood_Forest.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSpell,
                           filename: "Spell.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSuspense,
                           filename: "Suspense.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTelegraph,
                           filename: "Telegraph.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTiptoes,
                           filename: "Tiptoes.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTypewriters,
                           filename: "Typewriters.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemUpdate,
                           filename: "Update.caf",
                           systemSoundsSubdirectory: ["New"]),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemSwish,
                           filename: "Swish.caf"),
        .createSystemSound(label: L10n.screenNotificationSettingsSoundSystemTweet,
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

    private static let systemLocation = {
        let systemRoot: URL
        if let simulatorRoot = ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] {
            systemRoot = URL(filePath: simulatorRoot)
        } else {
            systemRoot = URL(filePath: "/")
        }
        return systemRoot.appending(components: "System", "Library", "Audio", "UISounds", directoryHint: .isDirectory)
    }()

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
            root = Self.libraryLocation
        }
        
        return tone.relativePath.reduce(root) {
            $0.appending(component: $1)
        }
    }
}
