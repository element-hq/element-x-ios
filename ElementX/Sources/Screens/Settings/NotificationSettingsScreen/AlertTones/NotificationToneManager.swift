//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation
import UniformTypeIdentifiers

struct NotificationToneManager {
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol

    init(appSettings: AppSettings, userIndicatorController: UserIndicatorControllerProtocol) throws {
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController

        try FileManager.default.createDirectory(at: NotificationAlertTone.libraryLocation, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: NotificationAlertTone.selectedToneLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

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
    }

    enum ConversionError: Error {
        case converterSetupFailed
        case fileAlreadyExists
        case bufferCreationFailed
    }

    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outputURL = NotificationAlertTone.libraryLocation.appending(component: baseName).appendingPathExtension("caf")

        guard (try? outputURL.checkResourceIsReachable()) != true else {
            throw ConversionError.fileAlreadyExists
        }

        try convertToCAF(from: sourceURL, to: outputURL)

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

    func deleteCustomTone(_ alertTone: NotificationAlertTone) throws {
        guard alertTone.location.deletingLastPathComponent() == NotificationAlertTone.libraryLocation else {
            throw DeletionError.notACustomTone
        }

        try FileManager.default.removeItem(at: alertTone.location)
    }

    enum DeletionError: Error {
        case notACustomTone
    }

    enum ImportError: Error {
        case couldNotAccessSandboxedResource
    }
}
