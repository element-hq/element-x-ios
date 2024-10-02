//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    }
    
    deinit {
        sessionVerificationController.setDelegate(delegate: nil)
    }
    
    let callbacks = PassthroughSubject<SessionVerificationControllerProxyCallback, Never>()
        
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        sessionVerificationController.setDelegate(delegate: WeakSessionVerificationControllerProxy(proxy: self))
        
        do {
            try await sessionVerificationController.requestVerification()
            return .success(())
        } catch {
            return .failure(.failedRequestingVerification)
        }
    }
    
    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        do {
            try await sessionVerificationController.startSasVerification()
            return .success(())
        } catch {
            return .failure(.failedStartingSasVerification)
        }
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        do {
            try await sessionVerificationController.approveVerification()
            return .success(())
        } catch {
            return .failure(.failedApprovingVerification)
        }
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        do {
            try await sessionVerificationController.declineVerification()
            return .success(())
        } catch {
            return .failure(.failedDecliningVerification)
        }
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        do {
            try await sessionVerificationController.cancelVerification()
            return .success(())
        } catch {
            return .failure(.failedCancellingVerification)
        }
    }
    
    // MARK: - Private
    
    fileprivate func didAcceptVerificationRequest() {
        callbacks.send(.acceptedVerificationRequest)
    }
    
    fileprivate func didStartSasVerification() {
        callbacks.send(.startedSasVerification)
    }
    
    fileprivate func didReceiveData(_ data: [MatrixRustSDK.SessionVerificationEmoji]) {
        callbacks.send(.receivedVerificationData(data.map { emoji in
            SessionVerificationEmoji(symbol: emoji.symbol(), description: emoji.description())
        }))
    }
    
    fileprivate func didFail() {
        callbacks.send(.failed)
    }
    
    fileprivate func didFinish() {
        callbacks.send(.finished)
    }
    
    fileprivate func didCancel() {
        callbacks.send(.cancelled)
    }
}
