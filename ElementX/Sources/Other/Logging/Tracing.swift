//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum Tracing {
    /// The base filename used for log files. This may be suffixed by the target
    /// name and other log management metadata during rotation.
    static let filePrefix = "console"
    /// The directory that stores all of the log files.
    static var logsDirectory: URL {
        if ProcessInfo.isRunningIntegrationTests {
            "/Users/Shared"
        } else {
            logsDirectoryOverride ?? .appGroupLogsDirectory
        }
    }
    
    /// Set this to temporarily override the directory from which logs will be collected.
    /// This basically only affects ``logFiles``, and doesn't inform the SDK to write
    /// the logs to a different directory, which should be done before setting this.
    static var logsDirectoryOverride: URL?
    static var legacyLogsDirectory: URL {
        .appGroupContainerDirectory
    }
    
    static let fileExtension = "log"
    
    static func buildConfiguration(logLevel: LogLevel, traceLogPacks: Set<TraceLogPack>,
                                   currentTarget: String,
                                   filePrefix: String?,
                                   sentryURL: URL?) -> TracingConfiguration {
        let fileName = if let filePrefix {
            "\(Tracing.filePrefix)-\(filePrefix)"
        } else {
            Tracing.filePrefix
        }
        
        // Keep a minimum of 1 week of log files. In reality it will be longer
        // as the app is unlikely to be running continuously.
        let maxFiles: UInt64 = 24 * 7
        
        // Log everything on integration tests to check whether
        // the logs contain any sensitive data. See `integration-tests.yml`
        let level: LogLevel = ProcessInfo.isRunningIntegrationTests ? .trace : logLevel
        
        return .init(logLevel: level.rustLogLevel,
                     traceLogPacks: traceLogPacks.map(\.rustLogPack),
                     extraTargets: [currentTarget],
                     writeToStdoutOrSystem: true,
                     writeToFiles: .init(path: logsDirectory.path(percentEncoded: false),
                                         filePrefix: fileName,
                                         fileSuffix: fileExtension,
                                         maxFiles: maxFiles),
                     sentryDsn: sentryURL?.absoluteString)
    }
    
    /// A list of all log file URLs, sorted chronologically.
    static var logFiles: [URL] {
        logFiles(in: logsDirectory)
    }
    
    /// Collect all of the logs in the given directory, sorting them chronologically.
    private static func logFiles(in directory: URL) -> [URL] {
        var logFiles = [(url: URL, modificationDate: Date)]()
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: directory,
                                                includingPropertiesForKeys: [.contentModificationDateKey],
                                                options: .skipsSubdirectoryDescendants)
        
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
    
    static func migrateLogFiles() {
        MXLog.info("Moving log files to \(logsDirectory)")
        let fileManager = FileManager.default
        let oldLogFiles = logFiles(in: legacyLogsDirectory)
        
        for oldFileURL in oldLogFiles {
            do {
                let newFileURL = logsDirectory.appending(component: oldFileURL.lastPathComponent)
                try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                MXLog.info("Moved \(newFileURL.lastPathComponent)")
            } catch {
                MXLog.error("Failed to move \(oldFileURL.lastPathComponent): \(error.localizedDescription)")
                
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileWriteFileExistsError {
                    // By now there will already be some logs in the new directory, so there is likely to be
                    // one log file that cannot be removed. As this is a one-off operation lets just delete it.
                    MXLog.error("Attempting to delete log file \(oldFileURL.lastPathComponent)")
                    try? fileManager.removeItem(at: oldFileURL)
                }
            }
        }
    }
    
    /// Delete all log files.
    static func deleteLogFiles(in directory: URL) {
        let fileManager = FileManager.default
        
        // We don't simply delete logsDirectory as once upon a time the logs
        // we written to the very top-level of the app group container and
        // there's a migration in place for old users of the app.
        for logFileURL in logFiles(in: directory) {
            try? fileManager.removeItem(at: logFileURL)
        }
    }
}
