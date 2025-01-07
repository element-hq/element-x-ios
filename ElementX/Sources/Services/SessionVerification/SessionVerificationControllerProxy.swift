//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

private class WeakSessionVerificationControllerProxy: SessionVerificationControllerDelegate {
    private weak var proxy: SessionVerificationControllerProxy?
    
    init(proxy: SessionVerificationControllerProxy) {
        self.proxy = proxy
    }
    
    // MARK: - SessionVerificationControllerDelegate
    
    func didReceiveVerificationRequest(details: MatrixRustSDK.SessionVerificationRequestDetails) {
        proxy?.didReceiveVerificationRequest(details: details)
    }
    
    func didReceiveVerificationData(data: MatrixRustSDK.SessionVerificationData) {
        switch data {
        // We can handle only emojis for now
        case .emojis(let emojis, _):
            proxy?.didReceiveData(emojis)
        default:
            break
        }
    }
    
    func didAcceptVerificationRequest() {
        proxy?.didAcceptVerificationRequest()
    }
    
    func didStartSasVerification() {
        proxy?.didStartSasVerification()
    }
    
    func didFail() {
        proxy?.didFail()
    }
    
    func didCancel() {
        proxy?.didCancel()
    }
    
    func didFinish() {
        proxy?.didFinish()
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
            try await sessionVerificationController.acknowledgeVerificationRequest(senderId: details.senderID, flowId: details.flowID)
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
            return .success(())
        } catch {
            MXLog.error("Failed requesting session verification with error: \(error)")
            return .failure(.failedAcceptingVerificationRequest)
        }
    }
        
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        MXLog.info("Requesting session verification")
        
        do {
            try await sessionVerificationController.requestVerification()
            return .success(())
        } catch {
            MXLog.error("Failed requesting session verification with error: \(error)")
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
        
        let details = SessionVerificationRequestDetails(senderID: details.senderId,
                                                        flowID: details.flowId,
                                                        deviceID: details.deviceId,
                                                        displayName: details.displayName,
                                                        firstSeenDate: Date(timeIntervalSince1970: TimeInterval(details.firstSeenTimestamp / 1000)))
        
        actions.send(.receivedVerificationRequest(details: details))
    }
    
    fileprivate func didAcceptVerificationRequest() {
        MXLog.info("Accepted verification request")
        
        actions.send(.acceptedVerificationRequest)
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
