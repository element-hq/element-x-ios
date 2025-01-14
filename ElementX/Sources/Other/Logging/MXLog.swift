//
// Copyright 2024 New Vector Ltd.
// Copyright 2021-2024 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    }
    
    // Rust side crashes if invoking setupTracing multiple times
    private static var didConfigureOnce = false
    
    private static var rootSpan: Span!
    private static var currentTarget: String!
    
    static func configure(currentTarget: String,
                          filePrefix: String?,
                          logLevel: LogLevel) {
        guard !didConfigureOnce else { return }
        
        Tracing.setup(logLevel: logLevel, currentTarget: currentTarget, filePrefix: filePrefix)
        
        self.currentTarget = currentTarget
        
        rootSpan = Span(file: #file, line: #line, level: .info, target: self.currentTarget, name: "root")
        rootSpan.enter()
        
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
    
    // periphery:ignore:parameters function,column
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
        
        return Span(file: file, line: UInt32(line), level: level.rustLogLevel, target: currentTarget, name: name)
    }
    
    // periphery:ignore:parameters function,column,context
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
        
        logEvent(file: (file as NSString).lastPathComponent, line: UInt32(line), level: level.rustLogLevel, target: currentTarget, message: "\(message)")
    }
}
