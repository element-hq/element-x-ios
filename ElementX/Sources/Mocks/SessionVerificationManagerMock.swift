//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension SessionVerificationManagerMock {
    struct Configuration {
        var actionsPublisher: AnyPublisher<SessionVerificationManagerAction, Never> = Empty().eraseToAnyPublisher()
        /// A request to send each time the UI tests signal an incoming verification request, replacing the `actionsPublisher`.
        var signalledRequest: SessionVerificationRequest?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        guard let request = configuration.signalledRequest else {
            actionsPublisher = configuration.actionsPublisher
            return
        }
        
        do {
            let client = try UITestsSignalling.Client(mode: .app)
            actionsPublisher = client.signals
                .filter { $0 == .sessionVerification(.incomingRequest) }
                .map { [client] _ in // Capturing the client also keeps it listening.
                    Task { try? client.send(.success) } // Sent *after* the request has been handled.
                    return .receivedRequest(request)
                }
                .eraseToAnyPublisher()
        } catch {
            fatalError("Failure setting up signalling: \(error)")
        }
    }
}
