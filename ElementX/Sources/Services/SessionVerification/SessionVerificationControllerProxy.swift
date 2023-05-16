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

import Combine
import Foundation
import MatrixRustSDK

private class WeakSessionVerificationControllerProxy: SessionVerificationControllerDelegate {
    private weak var proxy: SessionVerificationControllerProxy?
    
    init(proxy: SessionVerificationControllerProxy) {
        self.proxy = proxy
    }
    
    // MARK: - SessionVerificationControllerDelegate
    
    func didReceiveVerificationData(data: [MatrixRustSDK.SessionVerificationEmoji]) {
        proxy?.didReceiveData(data)
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
    
    var isVerified: Bool {
        sessionVerificationController.isVerified()
    }
    
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
