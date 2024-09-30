//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RustTracing {
    /// The base filename used for log files. This may be suffixed by the target
    /// name and other log management metadata during rotation.
    static let filePrefix = "console"
    /// The directory that stores all of the log files.
    static var logsDirectory: URL { .appGroupContainerDirectory }
    
    private(set) static var currentTracingConfiguration: TracingConfiguration?
    static func setup(configuration: TracingConfiguration) {
        currentTracingConfiguration = configuration
        
        // Keep a minimum of 1 week of log files. In reality it will be longer
        // as the app is unlikely to be running continuously.
        let maxFiles: UInt64 = 24 * 7
        
        setupTracing(config: .init(filter: configuration.filter,
                                   writeToStdoutOrSystem: true,
                                   writeToFiles: .init(path: logsDirectory.path(percentEncoded: false),
                                                       filePrefix: configuration.fileName,
                                                       fileSuffix: configuration.fileExtension,
                                                       maxFiles: maxFiles)))
    }
    
    /// A list of all log file URLs, sorted chronologically. This is only public for testing purposes, within
    /// the app please use ``copyLogs(to:)`` so that the files are name appropriates for QuickLook.
    static var logFiles: [URL] {
        var logFiles = [(url: URL, modificationDate: Date)]()
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: logsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
        
        // Find all *.log files and their modification dates.
        while let logURL = enumerator?.nextObject() as? URL {
            guard let resourceValues = try? logURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = resourceValues.contentModificationDate
            else { continue }
            
            if logURL.lastPathComponent.hasPrefix(filePrefix) {
                logFiles.append((logURL, modificationDate))
            }
        }
        
        let sortedFiles = logFiles.sorted { $0.modificationDate > $1.modificationDate }.map(\.url)
        
        MXLog.info("logFiles: \(sortedFiles.map(\.lastPathComponent))")
        
        return sortedFiles
    }
    
    /// Delete all log files.
    static func deleteLogFiles() {
        let fileManager = FileManager.default
        for logFileURL in logFiles {
            try? fileManager.removeItem(at: logFileURL)
        }
    }
}
