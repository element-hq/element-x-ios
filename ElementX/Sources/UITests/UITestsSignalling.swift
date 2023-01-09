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

import Foundation
import Network

enum UITestsSignal: String {
    /// An internal signal used to bring up the connection.
    case connect
    /// Ask the app to back paginate.
    case paginate
    /// Ask the app to simulate an incoming message.
    case incomingMessage
    /// The operation has completed successfully.
    case success
}

enum UITestsSignalError: Error {
    /// An unknown error occurred.
    case unknown
    /// Signalling could not be used as is hasn't been enabled.
    case disabled
    /// The connection was cancelled.
    case cancelled
    /// The connection hasn't been established.
    case notConnected
    /// Attempted to receive multiple signals at once.
    case awaitingAnotherSignal
    /// A network error occurred.
    case nwError(NWError)
    /// An unexpected signal was received. This error isn't used internally.
    case unexpected
}

enum UITestsSignalling {
    /// A network listener that can be used in the UI tests runner to create a two-way `Connection` with the app.
    class Listener {
        /// The underlying network listener.
        private let listener: NWListener
        
        /// The established connection. This is stored in case the connection is established
        /// before `connection()` is awaited and so the continuation is still `nil`.
        private var establishedConnection: Connection?
        /// The continuation to call when a connection is established.
        private var connectionContinuation: CheckedContinuation<Connection, Error>?
        
        /// Creates a new signalling `Listener` and starts listening.
        init() throws {
            listener = try NWListener(using: .udp, on: 1234)
            listener.newConnectionHandler = { [weak self] nwConnection in
                let connection = Connection(nwConnection: nwConnection)
                nwConnection.start(queue: .main)
                nwConnection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        connection.receiveNextMessage()
                        self?.establishedConnection = connection
                        self?.connectionContinuation?.resume(returning: connection)
                    case .failed(let error):
                        self?.connectionContinuation?.resume(with: .failure(error))
                    default:
                        break
                    }
                }
                self?.listener.cancel() // Stop listening for connections when one is discovered.
            }
            listener.start(queue: .main)
        }
        
        /// Returns the negotiated `Connection` as and when it has been established.
        func connection() async throws -> Connection {
            guard listener.state == .setup else { throw UITestsSignalError.unknown }
            if let establishedConnection {
                return establishedConnection
            }
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.connectionContinuation = continuation
            }
        }
        
        /// Stops the listening when a connection hasn't been established.
        func cancel() {
            listener.cancel()
            if let connectionContinuation {
                connectionContinuation.resume(throwing: UITestsSignalError.cancelled)
                self.connectionContinuation = nil
            }
        }
    }

    /// A two-way UDP connection that can be used for signalling between the app and the UI tests runner.
    /// The connection should be created as follows:
    /// - Create a `Listener` in the UI tests before launching the app. This will automatically start listening for a connection.
    /// - With in the App, create a `Connection` and call `connect()` to establish a connection.
    /// - Await the `connection()` on the `Listener` when you need to send the signal.
    /// - The two `Connection` objects can now be used for two-way signalling.
    class Connection {
        /// The underlying network connection.
        private let connection: NWConnection
        /// A continuation to call each time a signal is received.
        private var nextMessageContinuation: CheckedContinuation<UITestsSignal, Error>?
        
        /// Creates a new signalling `Connection`.
        init() {
            connection = NWConnection(host: "127.0.0.1", port: 1234, using: .udp)
        }
        
        /// Creates a new signalling `Connection` from an established `NWConnection`.
        fileprivate init(nwConnection: NWConnection) {
            connection = nwConnection
        }
        
        /// Attempts to establish a connection with a `Listener`.
        func connect() async throws {
            guard connection.state == .setup else { return }
            
            return try await withCheckedThrowingContinuation { continuation in
                connection.start(queue: .main)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        self.receiveNextMessage()
                        continuation.resume()
                        Task { try await self.send(.connect) }
                    case .failed(let error):
                        continuation.resume(with: .failure(error))
                    default:
                        break
                    }
                }
            }
        }
        
        /// Stops the connection.
        func disconnect() {
            connection.cancel()
            if let nextMessageContinuation {
                nextMessageContinuation.resume(throwing: UITestsSignalError.cancelled)
                self.nextMessageContinuation = nil
            }
        }
        
        /// Sends a message to the other side of the connection.
        func send(_ signal: UITestsSignal) async throws {
            guard connection.state == .ready else { throw UITestsSignalError.notConnected }
            let data = signal.rawValue.data(using: .utf8)
            connection.send(content: data, completion: .idempotent)
        }
        
        /// Returns the next message received from the other side of the connection.
        func receive() async throws -> UITestsSignal {
            guard connection.state == .ready else { throw UITestsSignalError.notConnected }
            guard nextMessageContinuation == nil else { throw UITestsSignalError.awaitingAnotherSignal }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.nextMessageContinuation = continuation
            }
        }
        
        /// Processes the next message received by the connection.
        fileprivate func receiveNextMessage() {
            connection.receiveMessage { [weak self] completeContent, _, isComplete, error in
                guard let self else { return }
                guard isComplete else { fatalError("Partial messages not supported") }
                
                guard let completeContent,
                      let message = String(data: completeContent, encoding: .utf8),
                      let signal = UITestsSignal(rawValue: message)
                else {
                    let error: UITestsSignalError = error.map { .nwError($0) } ?? .unknown
                    self.nextMessageContinuation?.resume(with: .failure(error))
                    self.nextMessageContinuation = nil
                    return
                }
                
                if signal != .connect {
                    self.nextMessageContinuation?.resume(returning: signal)
                    self.nextMessageContinuation = nil
                }
                
                self.receiveNextMessage()
            }
        }
    }
}
