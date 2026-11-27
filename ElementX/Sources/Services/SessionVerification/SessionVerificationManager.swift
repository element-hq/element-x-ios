//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

final class SessionVerificationManager: SessionVerificationManagerProtocol {
    private var requestCancellables: [String: AnyCancellable] = [:]
    
    private let actionsSubject = PassthroughSubject<SessionVerificationManagerAction, Never>()
    var actionsPublisher: AnyPublisher<SessionVerificationManagerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    func add(_ userSession: UserSessionProtocol) {
        let userID = userSession.clientProxy.userID
        
        // The controller is only built once the verification state is known, and building it can fail.
        let sessionVerificationControllerPublisher = userSession.sessionSecurityStatePublisher
            .filter { $0.verificationState != .unknown }
            .compactMap { _ in userSession.clientProxy.sessionVerificationController }
            .first()
        
        requestCancellables[userID] = sessionVerificationControllerPublisher
            .flatMap(\.actions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard case .receivedVerificationRequest(let details) = action else { return }
                MXLog.info("Received session verification request for \(userID)")
                
                let sender: SessionVerificationRequest.Sender = details.senderProfile.id == userID ? .ownDevice : .otherUser
                self?.actionsSubject.send(.receivedRequest(.init(userSession: userSession, details: details, sender: sender)))
            }
    }
    
    func remove(userID: String) {
        requestCancellables[userID] = nil
    }
}
