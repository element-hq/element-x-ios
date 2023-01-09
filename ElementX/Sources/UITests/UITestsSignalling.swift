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
    /// A UDP server that can be used for signalling between the UI tests jig and the app.
    /// The server should be instantiated on the UI tests side.
    class Server {
        private let listener: NWListener
        
        var client: Client?
        var connectionContinuation: CheckedContinuation<Client, Error>?
        
        /// Creates a new signalling server.
        init() throws {
            listener = try NWListener(using: .udp, on: 1234)
            start()
        }
        
        func start() {
            guard listener.state == .setup else { return }
            
            listener.newConnectionHandler = { [weak self] connection in
                let client = Client(connection: connection)
                connection.start(queue: .main)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        client.receiveNextMessage()
                        self?.connectionContinuation?.resume(returning: client)
                    case .failed(let error):
                        self?.connectionContinuation?.resume(with: .failure(error))
                    default:
                        break
                    }
                }
                self?.listener.cancel()
                self?.client = client
            }
            listener.start(queue: .main)
        }
        
        /// Listens for a client and attempts to negotiate a connection when one is discovered.
        func connect() async throws -> Client {
            guard listener.state == .setup else { throw UITestsSignalError.unknown }
            if let client {
                return client
            }
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.connectionContinuation = continuation
            }
        }
        
        /// Stops the the listener if when a connection hasn't been established.
        func disconnect() {
            listener.cancel()
            if let connectionContinuation {
                connectionContinuation.resume(throwing: UITestsSignalError.cancelled)
                self.connectionContinuation = nil
            }
        }
    }

    /// A UDP client that can be used for signalling between the app and the UI tests jig.
    /// The client should be instantiated on the app side.
    class Client {
        let connection: NWConnection
        var nextMessageContinuation: CheckedContinuation<UITestsSignal, Error>?
        
        /// Creates a new signalling client.
        init() {
            connection = NWConnection(host: "127.0.0.1", port: 1234, using: .udp)
        }
        
        init(connection: NWConnection) {
            self.connection = connection
        }
        
        /// Attempts to connect to a server.
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
        
        /// Sends a message to the connected client/server.
        func send(_ signal: UITestsSignal) async throws {
            guard connection.state == .ready else { throw UITestsSignalError.notConnected }
            let data = signal.rawValue.data(using: .utf8)
            connection.send(content: data, completion: .idempotent)
        }
        
        /// Returns the next message received by the client/server.
        func receive() async throws -> UITestsSignal {
            guard connection.state == .ready else { throw UITestsSignalError.notConnected }
            guard nextMessageContinuation == nil else { throw UITestsSignalError.awaitingAnotherSignal }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.nextMessageContinuation = continuation
            }
        }
        
        /// Processes the next message received by the client/server
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
