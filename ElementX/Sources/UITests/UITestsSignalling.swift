//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import KZFileWatchers
import SwiftUI

extension Notification.Name: @retroactive Codable { }

enum UITestsSignal: Codable, Equatable {
    /// An internal signal used to indicate that one side of the connection is ready.
    case ready
    /// The operation has completed successfully.
    case success
    
    case timeline(Timeline)
    enum Timeline: Codable, Equatable {
        /// Ask the app to back paginate.
        case paginate
        /// Ask the app to simulate an incoming message.
        case incomingMessage
        /// Ask the app to simulate focussing on an event ID.
        case focusOnEvent(String)
    }
    
    /// Posts a notification.
    case notification(name: Notification.Name)
    
    case accessibilityAudit(AccessibilityAudit)
    enum AccessibilityAudit: Codable, Equatable {
        /// Ask the app for the next preview.
        case nextPreview
        /// Tell the test runner about a loaded preview.
        case nextPreviewReady(name: String)
        /// Tell the test runner that there are no more previews.
        case noMorePreviews
    }
}

enum UITestsSignalError: String, LocalizedError {
    /// The app client failed to start as the tests client isn't ready.
    case testsClientNotReady
    /// Failed to send a signal as a connection hasn't been established.
    case notConnected
    
    var errorDescription: String? { "UITestsSignalError.\(rawValue)" }
}

enum UITestsSignalling {
    /// A two-way file-based signalling client that can be used to signal between the app and the UI tests runner.
    /// The connection should be created as follows:
    /// - Create a `Client` in `tests` mode in your UI tests before launching the app. It will start listening for signals.
    /// - Within the app, create a `Client` in `app` mode. This will check that the tests are ready and echo back that the app is too.
    /// - Call `waitForApp()` in the tests when you need to send the signal. This will suspend execution until the app has signalled it is ready.
    /// - The two `Client` objects can now be used for two-way signalling.
    class Client {
        /// The file watcher responsible for receiving signals.
        private let fileWatcher: FileWatcher.Local
        
        /// The file name used for the connection.
        ///
        /// The device name is included to allow UI tests to run on multiple devices simultaneously.
        /// When using parallel execution, each execution will spawn a simulator clone with its own unique name.
        private let fileURL = {
            let directory = URL(filePath: "/Users/Shared")
            let deviceName = (UIDevice.current.name).replacing(" ", with: "-")
            return directory.appending(component: "UITestsSignalling-\(deviceName)")
        }()
        
        /// A mode that defines the behaviour of the client.
        enum Mode: Codable { case app, tests }
        /// The mode that the client is using.
        let mode: Mode
        
        /// A publisher the will be sent every time a new signal is received.
        let signals = PassthroughSubject<UITestsSignal, Never>()
        
        /// Whether or not the client has established a connection.
        private(set) var isConnected = false
        
        /// Creates a new signalling `Client`.
        init(mode: Mode) throws {
            fileWatcher = .init(path: fileURL.path())
            self.mode = mode
            
            switch mode {
            case .tests:
                // The tests client is started first and writes to the file saying it is ready.
                try rawMessage(.ready).write(to: fileURL, atomically: false, encoding: .utf8)
            case .app:
                // The app client is started second and checks that there is a ready signal from the tests.
                guard try String(contentsOf: fileURL, encoding: .utf8) == Message(mode: .tests, signal: .ready).rawValue else { throw UITestsSignalError.testsClientNotReady }
                isConnected = true
                // The app client then echoes back to the tests that it is now ready.
                try send(.ready)
            }
            
            try fileWatcher.start { [weak self] result in
                self?.handleFileRefresh(result)
            }
        }
        
        /// Suspends execution until the app's Client has signalled that it's ready.
        func waitForApp() async {
            guard mode == .tests else { fatalError("The app can't wait for itself.") }
            
            guard !isConnected else { return }
            await _ = signals.values.first { $0 == .ready }
            NSLog("UITestsSignalling: Connected to app.")
        }

        /// Stops listening for signals.
        func stop() throws {
            try fileWatcher.stop()
        }

        /// Sends a signal.
        func send(_ signal: UITestsSignal) throws {
            guard isConnected else { throw UITestsSignalError.notConnected }
            
            let rawMessage = rawMessage(signal)
            try rawMessage.write(to: fileURL, atomically: false, encoding: .utf8)
            NSLog("UITestsSignalling: Sent \(rawMessage)")
        }
        
        /// The signal formatted as a complete message string, including the identifier for this sender.
        private func rawMessage(_ signal: UITestsSignal) -> String {
            Message(mode: mode, signal: signal).rawValue
        }
        
        /// The complete data that is serialised to disk for signalling.
        /// This consists of the signal along with an identifier for the sender.
        private struct Message: Codable {
            let mode: Mode
            let signal: UITestsSignal
            
            init(mode: Mode, signal: UITestsSignal) {
                self.mode = mode
                self.signal = signal
            }
            
            var rawValue: String {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                
                guard let data = try? encoder.encode(self),
                      let rawMessage = String(data: data, encoding: .utf8) else {
                    return "unknown"
                }
                return rawMessage
            }
            
            init?(rawValue: String) {
                guard let data = rawValue.data(using: .utf8),
                      let value = try? JSONDecoder().decode(Self.self, from: data) else {
                    return nil
                }
                self = value
            }
        }
        
        /// Handles a file refresh to receive a new signal.
        fileprivate func handleFileRefresh(_ result: FileWatcher.RefreshResult) {
            switch result {
            case .noChanges:
                guard let data = try? Data(contentsOf: fileURL) else { return }
                processFileData(data)
            case .updated(let data):
                processFileData(data)
            }
        }
        
        /// Processes string data from the file and publishes its signal.
        private func processFileData(_ data: Data) {
            guard let rawMessage = String(data: data, encoding: .utf8),
                  let message = Message(rawValue: rawMessage),
                  message.mode != mode // Filter out messages sent by this client.
            else { return }
            
            if message.signal == .ready {
                isConnected = true
            }
            
            signals.send(message.signal)
            
            NSLog("UITestsSignalling: Received \(rawMessage)")
        }
    }
}
