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
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol

    /// Creates the manager and ensures required library directories exist.
    init(appSettings: AppSettings, userIndicatorController: UserIndicatorControllerProtocol) throws {
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController

        try FileManager.default.createDirectory(at: NotificationTone.libraryLocation, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: NotificationTone.selectedToneLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    /// Sets the given tone as the active notification alert tone.
    ///
    /// Copies the tone's audio file to `selectedToneLocation` and persists the selection in app settings.
    func setSelectedTone(_ alertTone: NotificationTone) {
        do {
            try? FileManager.default.removeItem(at: NotificationTone.selectedToneLocation)
            try FileManager.default.copyItem(at: alertTone.location, to: NotificationTone.selectedToneLocation)
            appSettings.selectedNotificationTone = alertTone
        } catch {
            let userIndicator = UserIndicator(type: .toast,
                                              title: UntranslatedL10n.screenNotificationSettingsSoundSetSoundErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error setting selected alert tone to designated location in filesystem: \(error)")
        }
    }

    /// Returns all user-imported CAF tones from the library directory, sorted by name.
    func customTones() -> [NotificationTone] {
        let availableFiles = try? FileManager
            .default
            .contentsOfDirectory(at: NotificationTone.libraryLocation, includingPropertiesForKeys: nil)

        return (availableFiles ?? [])
            .compactMap {
                let pathExtension = $0.pathExtension
                guard UTType(filenameExtension: pathExtension) == UTType("com.apple.coreaudio-format") else { return nil }

                return .createCustomUserSound(filename: $0.lastPathComponent)
            }
            .sorted()
    }

    /// Errors that can occur during audio file conversion.
    enum ConversionError: Error {
        /// `AVAudioConverter` could not be initialised for the given format pair.
        case converterSetupFailed
        /// A tone with the same filename already exists in the library.
        case fileAlreadyExists
        /// An `AVAudioPCMBuffer` could not be allocated.
        case bufferCreationFailed
    }

    /// Imports an audio file into the tone library, converting to CAF if the source is not already CAF.
    /// - Returns: The URL of the imported file in the library.
    @ConversionActor
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outputURL = NotificationTone.libraryLocation.appending(component: baseName).appendingPathExtension("caf")

        guard (try? outputURL.checkResourceIsReachable()) != true else {
            throw ConversionError.fileAlreadyExists
        }

        if sourceURL.pathExtension.lowercased() == "caf" {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        } else {
            try convertToCAF(from: sourceURL, to: outputURL)
        }

        return outputURL
    }

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
            throw ConversionError.bufferCreationFailed
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

    /// Removes a user-imported tone from the library.
    /// - Throws: `DeletionError.notACustomTone` if the tone is not stored in the library directory.
    func deleteCustomTone(_ alertTone: NotificationTone) throws {
        guard alertTone.location.deletingLastPathComponent() == NotificationTone.libraryLocation else {
            throw DeletionError.notACustomTone
        }

        try FileManager.default.removeItem(at: alertTone.location)
    }

    /// Errors that can occur during tone deletion.
    enum DeletionError: Error {
        /// The tone's file is not inside the user library directory and cannot be deleted.
        case notACustomTone
    }

    /// Errors that can occur during tone import.
    enum ImportError: Error {
        /// The source file could not be accessed due to sandbox restrictions.
        case couldNotAccessSandboxedResource
    }

    @globalActor
    actor ConversionActor {
        static let shared = ConversionActor()
    }
}
