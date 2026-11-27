//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

enum SessionVerificationManagerAction {
    /// An account received an incoming verification request.
    case receivedRequest(SessionVerificationRequest)
}

/// An incoming verification request, along with the session of the account that received it.
struct SessionVerificationRequest {
    enum Sender { case ownDevice, otherUser }
    
    let userSession: UserSessionProtocol
    let details: SessionVerificationRequestDetails
    let sender: Sender
}

// sourcery: AutoMockable
/// Watches every account's session verification requests, so they can be shown whichever account is on screen.
protocol SessionVerificationManagerProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<SessionVerificationManagerAction, Never> { get }
    
    /// Watches the account's verification requests.
    ///
    /// Adding an account again replaces the session it had before, e.g. after clearing its caches.
    func add(_ userSession: UserSessionProtocol)
    /// Stops watching the account's verification requests.
    func remove(userID: String)
}
