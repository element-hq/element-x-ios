//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
// Copyright 2021-2025 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// Logging utility that provies multiple logging levels as well as file output and rolling.
/// Its purpose is to provide a common entry for customizing logging and should be used throughout the code.
enum MXLog {
    private nonisolated(unsafe) static var rootSpan: Span!
    private nonisolated(unsafe) static var currentTarget: String!
    
    static func configure(currentTarget: String) {
        self.currentTarget = currentTarget
        
        rootSpan = Span(file: #file, line: #line, level: .info, target: self.currentTarget, name: "root", bridgeTraceId: nil)
        rootSpan.enter()
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
                        column: Int = #column) {
        log(message, level: .trace, file: file, function: function, line: line, column: column)
    }
    
    static func debug(_ message: Any,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      column: Int = #column) {
        log(message, level: .debug, file: file, function: function, line: line, column: column)
    }
    
    static func info(_ message: Any,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     column: Int = #column) {
        log(message, level: .info, file: file, function: function, line: line, column: column)
    }
    
    static func warning(_ message: Any,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        column: Int = #column) {
        log(message, level: .warn, file: file, function: function, line: line, column: column)
    }
    
    /// Log error.
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    static func error(_ message: Any,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      column: Int = #column) {
        log(message, level: .error, file: file, function: function, line: line, column: column)
    }
    
    /// Log failure.
    ///
    /// A failure is any type of programming error which should never occur in production. In `DEBUG` configuration
    /// any failure will raise `assertionFailure`
    ///
    /// - Parameters:
    ///     - message: Description of the error without any variables (this is to improve error aggregations by type)
    static func failure(_ message: Any,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        column: Int = #column) {
        log(message, level: .error, file: file, function: function, line: line, column: column)
        
        #if DEBUG
        assertionFailure("\(message)")
        #endif
    }
    
    #if DEBUG
    private static let devPrefix = URL.documentsDirectory.pathComponents[2].uppercased()
    /// A helper method for print debugging, only available on debug builds.
    ///
    /// When running on the simulator this will log `[USERNAME] message` so that
    /// you can easily filter the Xcode console to see only the logs you're interested in.
    static func dev(_ message: Any,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line,
                    column: Int = #column) {
        log("[\(devPrefix)] \(message)", level: .info, file: file, function: function, line: line, column: column)
    }
    #endif
    
    // MARK: - Private
    
    // periphery:ignore:parameters function,column
    private static func createSpan(_ name: String,
                                   level: LogLevel,
                                   file: String = #file,
                                   function: String = #function,
                                   line: Int = #line,
                                   column: Int = #column) -> Span {
        if Span.current().isNone() {
            rootSpan.enter()
        }
        
        return Span(file: file, line: UInt32(line), level: level.rustLogLevel, target: currentTarget, name: name, bridgeTraceId: nil)
    }
    
    // periphery:ignore:parameters function,column
    private static func log(_ message: Any,
                            level: LogLevel,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            column: Int = #column) {
        guard let rootSpan else {
            return
        }
        
        if Span.current().isNone() {
            rootSpan.enter()
        }
        
        logEvent(file: (file as NSString).lastPathComponent, line: UInt32(line), level: level.rustLogLevel, target: currentTarget, message: "\(message)")
    }
}
