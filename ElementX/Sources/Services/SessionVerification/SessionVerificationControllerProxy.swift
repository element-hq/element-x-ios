//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

private final class WeakSessionVerificationControllerProxy: SessionVerificationControllerDelegate {
    @MainActor private weak var proxy: SessionVerificationControllerProxy?
    
    @MainActor init(proxy: SessionVerificationControllerProxy) {
        self.proxy = proxy
    }
    
    // MARK: - SessionVerificationControllerDelegate
    
    // The delegate methods are called by the SDK from arbitrary threads,
    // hop to the main actor where the proxy lives.
    
    func didReceiveVerificationRequest(details: MatrixRustSDK.SessionVerificationRequestDetails) {
        Task { @MainActor in
            self.proxy?.didReceiveVerificationRequest(details: details)
        }
    }
    
    func didReceiveVerificationData(data: MatrixRustSDK.SessionVerificationData) {
        switch data {
        // We can handle only emojis for now
        case .emojis(let emojis, _):
            Task { @MainActor in
                self.proxy?.didReceiveData(emojis)
            }
        default:
            break
        }
    }
    
    func didAcceptVerificationRequest() {
        Task { @MainActor in
            self.proxy?.didAcceptVerificationRequest()
        }
    }
    
    func didStartSasVerification() {
        Task { @MainActor in
            self.proxy?.didStartSasVerification()
        }
    }
    
    func didFail() {
        Task { @MainActor in
            self.proxy?.didFail()
        }
    }
    
    func didCancel() {
        Task { @MainActor in
            self.proxy?.didCancel()
        }
    }
    
    func didFinish() {
        Task { @MainActor in
            self.proxy?.didFinish()
        }
    }
}

class SessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol {
    private let sessionVerificationController: SessionVerificationController
    
    init(sessionVerificationController: SessionVerificationController) {
        self.sessionVerificationController = sessionVerificationController
        sessionVerificationController.setDelegate(delegate: WeakSessionVerificationControllerProxy(proxy: self))
    }
    
    deinit {
        sessionVerificationController.setDelegate(delegate: nil)
    }
    
    let actions = PassthroughSubject<SessionVerificationControllerProxyAction, Never>()
    
    func acknowledgeVerificationRequest(details: SessionVerificationRequestDetails) async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Acknowledging verification request")
        
        do {
            try await sessionVerificationController.acknowledgeVerificationRequest(senderId: details.senderProfile.userID, flowId: details.flowID)
            return .success(())
        } catch {
            MXLog.error("Failed requesting session verification with error: \(error)")
            return .failure(.failedAcknowledgingVerificationRequest)
        }
    }
    
    func acceptVerificationRequest() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Accepting verification request")
        
        do {
            try await sessionVerificationController.acceptVerificationRequest()
            
            MXLog.info("Accepted verification request")
            actions.send(.acceptedVerificationRequest)
            
            return .success(())
        } catch {
            MXLog.error("Failed requesting session verification with error: \(error)")
            return .failure(.failedAcceptingVerificationRequest)
        }
    }
    
    func requestDeviceVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Requesting device verification")
        
        do {
            try await sessionVerificationController.requestDeviceVerification()
            return .success(())
        } catch {
            MXLog.error("Failed requesting device verification with error: \(error)")
            return .failure(.failedRequestingVerification)
        }
    }
    
    func requestUserVerification(_ userID: String) async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Requesting user verification")
        
        do {
            try await sessionVerificationController.requestUserVerification(userId: userID)
            return .success(())
        } catch {
            MXLog.error("Failed requesting verification for user \(userID) with error: \(error)")
            return .failure(.failedRequestingVerification)
        }
    }
    
    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Starting SAS verification")
        
        do {
            try await sessionVerificationController.startSasVerification()
            return .success(())
        } catch {
            MXLog.error("Failed starting SAS verification with error: \(error)")
            return .failure(.failedStartingSasVerification)
        }
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Approving verification")
        
        do {
            try await sessionVerificationController.approveVerification()
            return .success(())
        } catch {
            MXLog.error("Failed approving verification with error: \(error)")
            return .failure(.failedApprovingVerification)
        }
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Declining verification")
        
        do {
            try await sessionVerificationController.declineVerification()
            return .success(())
        } catch {
            MXLog.error("Failed declining verification with error: \(error)")
            return .failure(.failedDecliningVerification)
        }
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Cancelling verification")
        
        do {
            try await sessionVerificationController.cancelVerification()
            return .success(())
        } catch {
            MXLog.error("Failed cancelling verification with error: \(error)")
            return .failure(.failedCancellingVerification)
        }
    }
    
    // MARK: - Private
    
    fileprivate func didReceiveVerificationRequest(details: MatrixRustSDK.SessionVerificationRequestDetails) {
        MXLog.info("Received verification request \(details)")
        
        let details = SessionVerificationRequestDetails(senderProfile: UserProfileProxy(sdkUserProfile: details.senderProfile),
                                                        flowID: details.flowId,
                                                        deviceID: details.deviceId,
                                                        deviceDisplayName: details.deviceDisplayName,
                                                        firstSeenDate: Date(timeIntervalSince1970: TimeInterval(details.firstSeenTimestamp / 1000)))
        
        actions.send(.receivedVerificationRequest(details: details))
    }
    
    fileprivate func didAcceptVerificationRequest() {
        // Noop because the rust side state machine changes states before sending
        // the actual request, leading to race conditions with the SAS verification
        // startup. The `acceptedVerificationRequest` is now called from the `startSasVerification`
        // method above.
    }
    
    fileprivate func didStartSasVerification() {
        MXLog.info("Started SAS verification")
        
        actions.send(.startedSasVerification)
    }
    
    fileprivate func didReceiveData(_ data: [MatrixRustSDK.SessionVerificationEmoji]) {
        MXLog.info("Received verification data")
        
        actions.send(.receivedVerificationData(data.map { emoji in
            SessionVerificationEmoji(symbol: emoji.symbol(), description: emoji.description())
        }))
    }
    
    fileprivate func didFail() {
        actions.send(.failed)
    }
    
    fileprivate func didFinish() {
        actions.send(.finished)
    }
    
    fileprivate func didCancel() {
        actions.send(.cancelled)
    }
}
