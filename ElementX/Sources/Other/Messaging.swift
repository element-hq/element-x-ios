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

enum NetworkError: Error {
    case unknown
    case notConnected
    case awaitingAnotherMessage
    case nwError(NWError)
}

class MessageClient: MessagingProtocol {
    let connection: NWConnection
    var nextMessageContinuation: CheckedContinuation<String, Error>?
    
    init() {
        connection = NWConnection(host: "127.0.0.1", port: 1234, using: .udp)
    }
    
    func connect() async throws {
        guard connection.state == .setup else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.start(queue: .main)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.receiveNextMessage()
                    continuation.resume()
                    Task { try await self.send(message: "Ready") }
                case .failed(let error):
                    continuation.resume(with: .failure(error))
                default:
                    break
                }
            }
        }
    }
}

class MessageServer: MessagingProtocol {
    let listener: NWListener
    
    var connection: NWConnection
    var nextMessageContinuation: CheckedContinuation<String, Error>?
    
    init() throws {
        connection = NWConnection(host: "127.0.0.1", port: 0, using: .udp)
        listener = try NWListener(using: .udp, on: 1234)
    }
    
    func connect() async throws {
        guard listener.state == .setup else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            listener.newConnectionHandler = { connection in
                // TODO: Handle multiple connections
                connection.start(queue: .main)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        self.receiveNextMessage()
                        continuation.resume()
                    case .failed(let error):
                        continuation.resume(with: .failure(error))
                    default:
                        break
                    }
                }
                self.connection = connection
            }
            listener.start(queue: .main)
        }
    }
}

protocol MessagingProtocol: AnyObject {
    var connection: NWConnection { get }
    var nextMessageContinuation: CheckedContinuation<String, Error>? { get set }
}

extension MessagingProtocol {
    /// Sends a message to the connected client/server.
    func send(message: String) async throws {
        guard connection.state == .ready else { throw NetworkError.notConnected }
        let data = message.data(using: .utf8)
        connection.send(content: data, completion: .idempotent)
    }
    
    /// Returns the next message received by the client/server.
    func nextMessage() async throws -> String {
        guard connection.state == .ready else { throw NetworkError.notConnected }
        guard nextMessageContinuation == nil else { throw NetworkError.awaitingAnotherMessage }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.nextMessageContinuation = continuation
        }
    }
    
    ///
    fileprivate func receiveNextMessage() {
        connection.receiveMessage { [weak self] completeContent, _, isComplete, error in
            guard let self else { return }
            guard isComplete else { fatalError("Partial messages not supported") }
            
            defer { self.nextMessageContinuation = nil }
            
            guard let completeContent, let message = String(data: completeContent, encoding: .utf8) else {
                let error: NetworkError = error.map { .nwError($0) } ?? .unknown
                self.nextMessageContinuation?.resume(with: .failure(error))
                return
            }
            
            self.nextMessageContinuation?.resume(returning: message)
            
            self.receiveNextMessage()
        }
    }
}
