//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

struct SessionVerificationManagerTests {
    private let sessionVerificationManager = SessionVerificationManager()
    private let sessionVerificationControllerActions = PassthroughSubject<SessionVerificationControllerProxyAction, Never>()
    private let securityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .enabled))
    private let userSession: UserSessionMock
    
    init() {
        let clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        clientProxy.sessionVerificationController = SessionVerificationControllerProxyMock.configureMock(actions: sessionVerificationControllerActions)
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = securityStateSubject.asCurrentValuePublisher()
    }
    
    @Test("An account's incoming request is forwarded with the account's session and who sent it",
          arguments: [("@alice:matrix.org", true), ("@bob:matrix.org", false)])
    func requestForwarding(senderID: String, isFromOwnDevice: Bool) async throws {
        sessionVerificationManager.add(userSession)
        
        let deferred = deferFulfillment(sessionVerificationManager.actionsPublisher) { action in
            guard case .receivedRequest(let request) = action, (request.userSession as? UserSessionMock) === userSession else { return false }
            
            switch request.kind {
            case .fromOwnDevice(let details): return isFromOwnDevice && details.flowID == "flow-id"
            case .fromOtherUser(let details): return !isFromOwnDevice && details.flowID == "flow-id"
            case .toUser: return false
            }
        }
        sessionVerificationControllerActions.send(.receivedVerificationRequest(details: details(from: senderID)))
        try await deferred.fulfill()
    }
    
    @Test("Requests are only watched once the account's verification state is known")
    func unknownVerificationState() async throws {
        securityStateSubject.send(.init(verificationState: .unknown, recoveryState: .unknown))
        sessionVerificationManager.add(userSession)
        
        let deferredFailure = deferFailure(sessionVerificationManager.actionsPublisher, timeout: .milliseconds(300)) { _ in true }
        sessionVerificationControllerActions.send(.receivedVerificationRequest(details: details()))
        try await deferredFailure.fulfill()
        
        securityStateSubject.send(.init(verificationState: .unverified, recoveryState: .unknown))
        let deferred = deferFulfillment(sessionVerificationManager.actionsPublisher) { _ in true }
        sessionVerificationControllerActions.send(.receivedVerificationRequest(details: details()))
        try await deferred.fulfill()
    }
    
    @Test("A removed account's requests are no longer forwarded")
    func removal() async throws {
        sessionVerificationManager.add(userSession)
        
        sessionVerificationManager.remove(userID: "@alice:matrix.org")
        
        let deferredFailure = deferFailure(sessionVerificationManager.actionsPublisher, timeout: .milliseconds(300)) { _ in true }
        sessionVerificationControllerActions.send(.receivedVerificationRequest(details: details()))
        try await deferredFailure.fulfill()
    }
    
    // MARK: - Helpers
    
    private func details(from senderID: String = "@alice:matrix.org") -> SessionVerificationRequestDetails {
        .init(senderProfile: UserProfile(userID: senderID),
              flowID: "flow-id",
              deviceID: "device-id",
              deviceDisplayName: nil,
              firstSeenDate: .now)
    }
}
