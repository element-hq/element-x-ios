//
// Copyright 2021 The Matrix.org Foundation C.I.C
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

import Foundation
import SwiftyBeaver

/// Various MXLog configuration options. Used in conjunction with `MXLog.configure()`
public class MXLogConfiguration: NSObject {
    /// the desired log level. `.verbose` by default.
    public var logLevel = MXLogLevel.verbose
    
    /// whether logs should be written directly to files. `false` by default.
    public var redirectLogsToFiles = false
    
    /// the maximum total space to use for log files in bytes. `100MB` by default.
    public var logFilesSizeLimit: UInt = 100 * 1024 * 1024 // 100MB
    
    /// the maximum number of log files to use before rolling. `50` by default.
    public var maxLogFilesCount: UInt = 50
    
    /// the subname for log files. Files will be named as 'console-[subLogName].log'. `nil` by default
    public var subLogName: String?
}

/// MXLog logging levels. Use .none to disable logging entirely.
public enum MXLogLevel: UInt {
    case none
    case verbose
    case debug
    case info
    case warning
    case error
}

private var logger: SwiftyBeaver.Type = {
    let logger = SwiftyBeaver.self
    MXLog.configureLogger(logger, withConfiguration: MXLogConfiguration())
    return logger
}()

/**
 Logging utility that provies multiple logging levels as well as file output and rolling.
 Its purpose is to provide a common entry for customizing logging and should be used throughout the code.
 Please see `MXLog.h` for Objective-C options.
 */
public class MXLog: NSObject {
    /// Method used to customize MXLog's behavior.
    /// Called automatically when first accessing the logger with the default values.
    /// Please see `MXLogConfiguration` for all available options.
    /// - Parameters:
    ///     - configuration: the `MXLogConfiguration` instance to use
    public static func configure(_ configuration: MXLogConfiguration) {
        configureLogger(logger, withConfiguration: configuration)
    }
    
    public static func verbose(_ message: @autoclosure () -> Any,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        logger.verbose(message(), file, function, line: line, context: context)
    }
    
    public static func debug(_ message: @autoclosure () -> Any,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        logger.debug(message(), file, function, line: line, context: context)
    }
    
    public static func info(_ message: @autoclosure () -> Any,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            context: Any? = nil) {
        logger.info(message(), file, function, line: line, context: context)
    }
    
    public static func warning(_ message: @autoclosure () -> Any,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        logger.warning(message(), file, function, line: line, context: context)
    }
    
    /// Log error with additional details
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    ///     - context: Additional context-dependent details about the issue
    public static func error(_ message: @autoclosure () -> Any,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        logger.error(message(), file, function, line: line, context: context)
    }
    
    /// Log failure with additional details
    ///
    /// A failure is any type of programming error which should never occur in production. In `DEBUG` configuration
    /// any failure will raise `assertionFailure`
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    ///     - context: Additional context-dependent details about the issue
    public static func failure(_ message: String,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        logger.error(message, file, function, line: line, context: context)
        #if DEBUG
        assertionFailure("\(message)")
        #endif
    }
    
    // MARK: - Private
    
    fileprivate static func configureLogger(_ logger: SwiftyBeaver.Type, withConfiguration configuration: MXLogConfiguration) {
        if let subLogName = configuration.subLogName {
            MXLogger.setSubLogName(subLogName)
        }
        
        MXLogger.redirectNSLog(toFiles: configuration.redirectLogsToFiles,
                               numberOfFiles: configuration.maxLogFilesCount,
                               sizeLimit: configuration.logFilesSizeLimit)
        
        guard configuration.logLevel != .none else {
            logger.removeAllDestinations()
            return
        }
        
        logger.removeAllDestinations()
        
        let consoleDestination = ConsoleDestination()
        consoleDestination.useNSLog = true
        consoleDestination.asynchronously = false
        consoleDestination.format = "$C$N.$F:$l $M $X$c" // See https://docs.swiftybeaver.com/article/20-custom-format
        consoleDestination.levelColor.verbose = ""
        consoleDestination.levelColor.debug = ""
        consoleDestination.levelColor.info = ""
        consoleDestination.levelColor.warning = "⚠️ "
        consoleDestination.levelColor.error = "🚨 "
        
        switch configuration.logLevel {
        case .verbose:
            consoleDestination.minLevel = .verbose
        case .debug:
            consoleDestination.minLevel = .debug
        case .info:
            consoleDestination.minLevel = .info
        case .warning:
            consoleDestination.minLevel = .warning
        case .error:
            consoleDestination.minLevel = .error
        case .none:
            break
        }
        logger.addDestination(consoleDestination)
    }
}
