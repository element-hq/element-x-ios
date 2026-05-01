//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation
import UniformTypeIdentifiers

/// Manages notification tone selection, import, conversion, and deletion.
struct NotificationToneManager {
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol

    /// Creates the manager and ensures required library directories exist.
    init(appSettings: AppSettings, userIndicatorController: UserIndicatorControllerProtocol) throws {
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController

        try FileManager.default.createDirectory(at: NotificationAlertTone.libraryLocation, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: NotificationAlertTone.selectedToneLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    /// Sets the given tone as the active notification alert tone.
    ///
    /// Copies the tone's audio file to `selectedToneLocation` and persists the selection in app settings.
    func setSelectedTone(_ alertTone: NotificationAlertTone) {
        do {
            try? FileManager.default.removeItem(at: NotificationAlertTone.selectedToneLocation)
            try FileManager.default.copyItem(at: alertTone.location, to: NotificationAlertTone.selectedToneLocation)
            appSettings.selectedNotificationTone = alertTone
        } catch {
            let userIndicator = UserIndicator(type: .toast,
                                              title: UntranslatedL10n.screenNotificationSettingsConfigurationAlertToneSetToneErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error setting selected alert tone to designated location in filesystem: \(error)")
        }
    }

    /// Returns all user-imported CAF tones from the library directory, sorted by name.
    func getCustomTones() -> [NotificationAlertTone] {
        let availableFiles = try? FileManager
            .default
            .contentsOfDirectory(at: NotificationAlertTone.libraryLocation, includingPropertiesForKeys: nil)

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
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outputURL = NotificationAlertTone.libraryLocation.appending(component: baseName).appendingPathExtension("caf")

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

    private func convertToCAF(from sourceURL: URL, to destURL: URL) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)

        // CAF + LPCM is the safest choice; file type inferred from .caf extension
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sourceFile.fileFormat.sampleRate,
            AVNumberOfChannelsKey: sourceFile.fileFormat.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let destFile = try AVAudioFile(forWriting: destURL, settings: outputSettings)

        guard let converter = AVAudioConverter(from: sourceFile.processingFormat,
                                               to: destFile.processingFormat) else {
            throw ConversionError.converterSetupFailed
        }

        let frameCount: AVAudioFrameCount = 4096
        guard let inputBuf = AVAudioPCMBuffer(pcmFormat: sourceFile.processingFormat, frameCapacity: frameCount) else {
            MXLog.error("Error creating input conversion buffer: \(sourceFile.processingFormat) \(frameCount)")
            throw ConversionError.bufferCreationFailed
        }
        guard let outputBuf = AVAudioPCMBuffer(pcmFormat: destFile.processingFormat, frameCapacity: frameCount) else {
            MXLog.error("Error creating output conversion buffer: \(destFile.processingFormat) \(frameCount)")
            throw ConversionError.bufferCreationFailed
        }

        var done = false

        while !done {
            var conversionError: NSError?

            let status = converter.convert(to: outputBuf, error: &conversionError) { inputPacketCount, inputConverterStatus in
                MXLog.info("input packet count: \(inputPacketCount)")
                do {
                    try sourceFile.read(into: inputBuf, frameCount: frameCount)
                    if inputBuf.frameLength == 0 {
                        inputConverterStatus.pointee = .endOfStream
                        done = true
                    } else {
                        inputConverterStatus.pointee = .haveData
                    }
                } catch {
                    inputConverterStatus.pointee = .endOfStream
                    done = true
                }
                return inputBuf
            }

            if status == .error, let err = conversionError { throw err }
            if outputBuf.frameLength > 0 { try destFile.write(from: outputBuf) }
            if status == .endOfStream { break }
        }
    }

    /// Removes a user-imported tone from the library.
    /// - Throws: `DeletionError.notACustomTone` if the tone is not stored in the library directory.
    func deleteCustomTone(_ alertTone: NotificationAlertTone) throws {
        guard alertTone.location.deletingLastPathComponent() == NotificationAlertTone.libraryLocation else {
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
}
