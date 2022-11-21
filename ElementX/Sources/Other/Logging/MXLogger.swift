//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

/// The `MXLogger` tool redirects NSLog output into a fixed pool of files.
/// Another log file is used every time `MXLogger redirectNSLog(toFiles: true)`
/// is called. The pool contains 3 files.
///
/// `MXLogger` can track and log uncaught exceptions or crashes.
class MXLogger {
    /// stderr so it can be restored.
    static var stderrSave: Int32 = 0
    
    private enum Constants {
        /// The filename used for the crash log.
        static let crashLogFileName = "crash.log"
    }
    
    /// Redirect NSLog output to MXLogger files.
    ///
    /// It is advised to condition this redirection in `#if (!isatty(STDERR_FILENO))` block to enable
    /// it only when the device is not attached to the debugger.
    ///
    /// - Parameters:
    ///   - redirectToFiles: `true` to enable the redirection.
    ///   - numberOfFiles: number of files to keep (default is 10).
    ///   - sizeLimit: size limit of log files in bytes. 0 means no limitation, the default value for other methods
    static func redirectNSLog(toFiles redirectToFiles: Bool, numberOfFiles: UInt = 10, sizeLimit: UInt = 0) {
        if redirectToFiles {
            var tempLog = ""
            
            // Do a circular buffer based on X files
            for index in (0...(numberOfFiles - 2)).reversed() {
                rotateLog(at: index, tempLog: &tempLog)
            }

            // Save stderr so it can be restored.
            stderrSave = dup(STDERR_FILENO)

            let nsLogURL = logURL(for: "console\(subLogName).log")
            freopen((nsLogURL as NSURL).fileSystemRepresentation, "w+", stderr)

            MXLog.debug("redirectNSLogToFiles: true")
            if !tempLog.isEmpty {
                // We can now log into files
                MXLog.debug(tempLog)
            }
            
            removeExtraFiles(from: numberOfFiles)
            
            if sizeLimit > 0 {
                removeFiles(after: sizeLimit)
            }
        } else if stderrSave > 0 {
            // Flush before restoring stderr
            fflush(stderr)

            // Now restore stderr, so new output goes to console.
            dup2(stderrSave, STDERR_FILENO)
            close(stderrSave)
        }
    }
    
    private static func rotateLog(at index: UInt, tempLog: inout String) {
        let fileManager = FileManager.default
        
        let currentURL: URL
        let newURL: URL

        if index == 0 {
            currentURL = logURL(for: String("console\(subLogName).log"))
            newURL = logURL(for: String("console\(subLogName).1.log"))
        } else {
            currentURL = logURL(for: String("console\(subLogName).\(index).log"))
            newURL = logURL(for: String("console\(subLogName).\(index + 1).log"))
        }
        
        guard fileManager.fileExists(atPath: currentURL.path()) else { return }
        
        if fileManager.fileExists(atPath: newURL.path()) {
            // Temp log
            tempLog.append("removeItemAt: \(newURL)\n")
            
            do {
                try fileManager.removeItem(at: newURL)
            } catch {
                tempLog.append("removeItemAt: \(newURL). Error: \(error)\n")
            }
        }
        
        // Temp log
        tempLog.append("moveItemAt: \(currentURL) to: \(newURL)\n")
        
        do {
            try fileManager.moveItem(at: currentURL, to: newURL)
        } catch {
            tempLog.append("moveItemAt: \(currentURL) to: \(newURL). Error: \(error)\n")
        }
    }
    
    private static func logURL(for fileName: String) -> URL {
        MXLogger.logsFolderURL.appending(path: fileName)
    }
    
    /// Delete all log files.
    static func deleteLogFiles() {
        let fileManager = FileManager.default
        for logFileURL in logFiles {
            try? fileManager.removeItem(at: logFileURL)
        }
    }
    
    /// The list of all log file URLs.
    static var logFiles: [URL] {
        var logFiles = [URL]()
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: logsFolderURL, includingPropertiesForKeys: nil)
        
        // Find all *.log files
        while let logURL = enumerator?.nextObject() as? URL {
            if logURL.lastPathComponent.hasPrefix("console") {
                logFiles.append(logURL)
            }
        }
        
        MXLog.debug("logFiles: \(logFiles)")
        
        return logFiles
    }
    
    // MARK: - Exceptions and crashes
    
    /// Exceptions uncaught by try catch block are handled here
    static func handleUncaughtException(_ exception: NSException) {
        MXLogger.logCrashes(false)
        
        // Extract running app information
        let app = InfoPlistReader.target.bundleExecutable
        let appId = InfoPlistReader.target.bundleIdentifier
        let appVersion = "\(InfoPlistReader.target.bundleShortVersionString) (r\(InfoPlistReader.target.bundleVersion))"
        
        // Build the crash log
        let model = UIDevice.current.model
        let version = UIDevice.current.systemVersion
        
        let backtrace = exception.callStackSymbols
        let description = String(format: "%.0f - %@\n%@\nApplication: %@ (%@)\nApplication version: %@\nBuild: %@\n%@ %@\n\nMain thread: %@\n%@\n",
                                 Date.now.timeIntervalSince1970,
                                 NSDate(),
                                 exception.description,
                                 app, appId,
                                 appVersion,
                                 buildVersion ?? "Unknown",
                                 model, version,
                                 Thread.isMainThread ? "true" : "false",
                                 backtrace)

        // Write to the crash log file
        MXLogger.deleteCrashLog()
        let crashLog = crashLogURL
        try? description.write(to: crashLog, atomically: false, encoding: .utf8)
        
        MXLog.error("handleUncaughtException", context: ["description": description])
    }
    
    // Signals emitted by the app are handled here
    private static func handleSignal(_ signalValue: Int32) {
        // Throw a custom Objective-C exception
        // The Objective-C runtime will then be able to build a readable call stack in handleUncaughtException
        withVaList([signalValue]) { NSException.raise(.init("Signal detected"), format: "Signal detected: %d", arguments: $0) }
    }
    
    /// Make `MXLogger` catch and log unmanaged exceptions or application crashes.
    ///
    /// When such error happens, `MXLogger` stores the application stack trace into a file
    /// just before the application leaves. The path of this file is provided by `MXLogger.crashLog`.
    ///
    /// - Parameter enabled: `true` to enable the catch.
    static func logCrashes(_ enabled: Bool) {
        if enabled {
            // Handle not managed exceptions by ourselves
            NSSetUncaughtExceptionHandler { exception in
                MXLogger.handleUncaughtException(exception)
            }

            // Register signal event (seg fault & cie)
            signal(SIGABRT) { MXLogger.handleSignal($0) }
            signal(SIGILL) { MXLogger.handleSignal($0) }
            signal(SIGSEGV) { MXLogger.handleSignal($0) }
            signal(SIGFPE) { MXLogger.handleSignal($0) }
            signal(SIGBUS) { MXLogger.handleSignal($0) }
            signal(SIGABRT) { MXLogger.handleSignal($0) }
        } else {
            // Disable crash handling
            NSSetUncaughtExceptionHandler(nil)
            signal(SIGABRT, SIG_DFL)
            signal(SIGILL, SIG_DFL)
            signal(SIGSEGV, SIG_DFL)
            signal(SIGFPE, SIG_DFL)
            signal(SIGBUS, SIG_DFL)
        }
    }
    
    /// Set the app build version.
    /// It will be reported in crash report.
    static var buildVersion: String?
    
    /// Set a sub name for namespacing log files.
    ///
    /// A sub name must be set when running from an app extension because extensions can
    /// run in parallel to the app.
    /// It must be called before `redirectNSLog(toFiles)`.
    ///
    /// - Parameter name: the subname for log files. Files will be named as `console-[subLogName].log`
    /// Default is nil.
    static func setSubLogName(_ name: String) {
        if name.isEmpty {
            subLogName = ""
        } else {
            subLogName = "-\(name)"
        }
    }
    
    private static var subLogName = ""
    
    /// The URL used for a crash log file.
    static var crashLogURL: URL {
        MXLogger.logsFolderURL.appending(path: Constants.crashLogFileName)
    }
    
    /// The URL of the file containing the last application crash if one exists or `nil` if there is none.
    ///
    /// Only one crash log is stored at a time. The best moment for the app to handle it is the
    /// at its next startup.
    static var crashLog: URL? {
        let crashLogURL = MXLogger.crashLogURL
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: crashLogURL.path()) else { return nil }
        
        return crashLogURL
    }
    
    /// Delete the crash log file.
    static func deleteCrashLog() {
        let crashLog = MXLogger.crashLogURL
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: crashLog.path()) {
            try? fileManager.removeItem(at: crashLog)
        }
    }
    
    // MARK: - Private
    
    /// The folder where logs are stored
    private static var logsFolderURL: URL {
        .appGroupContainerDirectory
    }
    
    /// If `self.redirectNSLog(toFiles:numberOfFiles:)` is called with a lower numberOfFiles we need to do some cleanup.
    private static func removeExtraFiles(from count: UInt) {
        let fileManager = FileManager.default
        
        for index in count... {
            let fileName = "console\(subLogName).\(index).log"
            let logFile = logURL(for: fileName)
            
            if fileManager.fileExists(atPath: logFile.path()) {
                try? fileManager.removeItem(at: logFile)
                MXLog.debug("removeExtraFilesFromCount: \(count). removeItemAt: \(logFile)\n")
            } else {
                break
            }
        }
    }
    
    /// If `redirectNSLog(toFiles:sizeLimit:)` is called with a size limit, we may need to do some cleanup.
    private static func removeFiles(after sizeLimit: UInt) {
        var logSize: UInt = 0
        var indexExceedingSizeLimit: Int?
        let fileManager = FileManager.default
        
        // Start from console.1.log. Do not consider console.log. It should be almost empty
        for index in 1... {
            let fileName = "console\(subLogName).\(index).log"
            let logFile = logURL(for: fileName)
            
            if fileManager.fileExists(atPath: logFile.path()) {
                if let attributes = try? fileManager.attributesOfItem(atPath: logFile.path()), let fileSize = attributes[.size] as? UInt {
                    logSize += fileSize
                }
                
                if logSize >= sizeLimit {
                    indexExceedingSizeLimit = index
                    break
                }
            } else {
                break
            }
        }
        
        let logSizeString = logSize.formatted(.byteCount(style: .binary))
        let sizeLimitString = sizeLimit.formatted(.byteCount(style: .binary))
        
        if let indexExceedingSizeLimit {
            MXLog.debug("removeFilesAfterSizeLimit: Remove files from index \(indexExceedingSizeLimit) because logs are too large (\(logSizeString) for a limit of \(sizeLimitString)\n")
            removeExtraFiles(from: UInt(indexExceedingSizeLimit))
        } else {
            MXLog.debug("removeFilesAfterSizeLimit: No need: \(logSizeString) for a limit of \(sizeLimitString)\n")
        }
    }
}
