//
//  SessionVerificationControllerProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 06/06/2022.
//  Copyright © 2022 Element. All rights reserved.
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
    
    let callbacks = PassthroughSubject<SessionVerificationControllerProxyCallback, Never>()
    
    var isVerified: Bool {
        sessionVerificationController.isVerified()
    }
    
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        await Task.detached {
            do {
                try self.sessionVerificationController.requestVerification()
                return .success(())
            } catch {
                return .failure(.failedRequestingVerification)
            }
        }
        .value
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        await Task.detached {
            do {
                try self.sessionVerificationController.approveVerification()
                return .success(())
            } catch {
                return .failure(.failedApprovingVerification)
            }
        }
        .value
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        await Task.detached {
            do {
                try self.sessionVerificationController.declineVerification()
                return .success(())
            } catch {
                return .failure(.failedDecliningVerification)
            }
        }
        .value
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        await Task.detached {
            do {
                try self.sessionVerificationController.cancelVerification()
                return .success(())
            } catch {
                return .failure(.failedCancellingVerification)
            }
        }
        .value
    }
    
    // MARK: - Private
    
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
