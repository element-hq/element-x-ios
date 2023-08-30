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
import MatrixRustSDK

/**
 Logging utility that provies multiple logging levels as well as file output and rolling.
 Its purpose is to provide a common entry for customizing logging and should be used throughout the code.
 */
enum MXLog {
    private enum Constants {
        static let target = "elementx"
        
        // Avoid redirecting NSLogs to files if we are attached to a debugger.
        static let redirectToFiles = isatty(STDERR_FILENO) == 0
        
        /// the maximum number of log files to use before rolling. `10` by default.
        static let maxLogFileCount: UInt = 10
        
        /// the maximum total space to use for log files in bytes. `100MB` by default.
        static let logFilesSizeLimit: UInt = 100 * 1024 * 1024 // 100MB
    }
    
    // Rust side crashes if invoking setupTracing multiple times
    private static var didConfigureOnce = false
    
    private static var rootSpan: Span!
    private static var target: String!
    
    static func configure(target: String? = nil,
                          logLevel: TracingConfiguration.LogLevel,
                          otlpConfiguration: OTLPConfiguration? = nil,
                          redirectToFiles: Bool = Constants.redirectToFiles,
                          maxLogFileCount: UInt = Constants.maxLogFileCount,
                          logFileSizeLimit: UInt = Constants.logFilesSizeLimit) {
        guard didConfigureOnce == false else {
            if let target {
                MXLogger.setSubLogName(target)
            }
            
            // SubLogName needs to be set before calling configure in order to be applied
            MXLogger.configure(redirectToFiles: redirectToFiles,
                               maxLogFileCount: maxLogFileCount,
                               logFileSizeLimit: logFileSizeLimit)
            return
        }
        
        setupTracing(configuration: .init(logLevel: logLevel), otlpConfiguration: otlpConfiguration)
        
        if let target {
            self.target = target
            MXLogger.setSubLogName(target)
        } else {
            self.target = Constants.target
        }
        
        rootSpan = Span(file: #file, line: #line, level: .info, target: self.target, name: "root")
        
        rootSpan.enter()
        
        MXLogger.configure(redirectToFiles: redirectToFiles,
                           maxLogFileCount: maxLogFileCount,
                           logFileSizeLimit: logFileSizeLimit)
        
        didConfigureOnce = true
    }
    
    static func createSpan(_ name: String,
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line,
                           column: Int = #column) -> Span {
        createSpan(name, level: .info, file: file, function: function, line: line, column: column)
    }
    
    static func verbose(_ message: Any,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        column: Int = #column,
                        context: Any? = nil) {
        log(message, level: .trace, file: file, function: function, line: line, column: column, context: context)
    }
    
    static func debug(_ message: Any,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      column: Int = #column,
                      context: Any? = nil) {
        log(message, level: .debug, file: file, function: function, line: line, column: column, context: context)
    }
    
    static func info(_ message: Any,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     column: Int = #column,
                     context: Any? = nil) {
        log(message, level: .info, file: file, function: function, line: line, column: column, context: context)
    }
    
    static func warning(_ message: Any,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        column: Int = #column,
                        context: Any? = nil) {
        log(message, level: .warn, file: file, function: function, line: line, column: column, context: context)
    }
    
    /// Log error with additional details
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    ///     - context: Additional context-dependent details about the issue
    static func error(_ message: Any,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      column: Int = #column,
                      context: Any? = nil) {
        log(message, level: .error, file: file, function: function, line: line, column: column, context: context)
    }
    
    /// Log failure with additional details
    ///
    /// A failure is any type of programming error which should never occur in production. In `DEBUG` configuration
    /// any failure will raise `assertionFailure`
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    ///     - context: Additional context-dependent details about the issue
    static func failure(_ message: Any,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        column: Int = #column,
                        context: Any? = nil) {
        log(message, level: .error, file: file, function: function, line: line, column: column, context: context)
        
        #if DEBUG
        assertionFailure("\(message)")
        #endif
    }
    
    // MARK: - Private
    
    private static func createSpan(_ name: String,
                                   level: LogLevel,
                                   file: String = #file,
                                   function: String = #function,
                                   line: Int = #line,
                                   column: Int = #column) -> Span {
        guard didConfigureOnce else {
            fatalError()
        }
        
        if Span.current().isNone() {
            rootSpan.enter()
        }
        
        return Span(file: file, line: UInt32(line), level: level, target: target, name: name)
    }
    
    private static func log(_ message: Any,
                            level: LogLevel,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            column: Int = #column,
                            context: Any? = nil) {
        guard didConfigureOnce else {
            return
        }
        
        if Span.current().isNone() {
            rootSpan.enter()
        }
        
        logEvent(file: (file as NSString).lastPathComponent, line: UInt32(line), level: level, target: target, message: "\(message)")
    }
}
