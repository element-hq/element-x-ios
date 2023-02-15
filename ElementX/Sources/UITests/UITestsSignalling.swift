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

import Combine
import KZFileWatchers
import SwiftUI

enum UITestsSignal: String {
    /// An internal signal used to indicate that one side of the connection is ready.
    case ready
    /// Ask the app to back paginate.
    case paginate
    /// Ask the app to simulate an incoming message.
    case incomingMessage
    /// The operation has completed successfully.
    case success
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
        enum Mode: String { case app, tests }
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
                try rawSignal(.ready).write(to: fileURL, atomically: false, encoding: .utf8)
            case .app:
                // The app client is started second and checks that there is a ready signal from the tests.
                guard try String(contentsOf: fileURL) == "\(Mode.tests):\(UITestsSignal.ready)" else { throw UITestsSignalError.testsClientNotReady }
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
            
            let rawSignal = rawSignal(signal)
            try rawSignal.write(to: fileURL, atomically: false, encoding: .utf8)
            NSLog("UITestsSignalling: Sent \(rawSignal)")
        }
        
        /// The signal formatted as a string, prefixed with an identifier for the sender.
        /// E.g. The tests client would produce `tests:ready` for the ready signal.
        private func rawSignal(_ signal: UITestsSignal) -> String {
            "\(mode.rawValue):\(signal.rawValue)"
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
            guard let message = String(data: data, encoding: .utf8) else { return }
            
            let components = message.components(separatedBy: ":")
            
            guard components.count == 2,
                  components[0] != mode.rawValue, // Filter out messages sent by this client.
                  let signal = UITestsSignal(rawValue: components[1])
            else { return }
            
            if signal == .ready {
                isConnected = true
            }
            
            signals.send(signal)
            
            NSLog("UITestsSignalling: Received \(message)")
        }
    }
}
