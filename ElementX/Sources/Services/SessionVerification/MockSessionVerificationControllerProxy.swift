//
//  MockSessionVerificationControllerProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 07/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import Foundation
import MatrixRustSDK

struct MockSessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol {
    var callbacks = PassthroughSubject<SessionVerificationControllerProxyCallback, Never>()
    
    var isVerified = false
    
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            callbacks.send(.receivedVerificationData(Self.emojis))
        }
        
        return .success(())
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            callbacks.send(.finished)
        }
        
        return .success(())
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            callbacks.send(.cancelled)
        }
        
        return .success(())
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) {
            callbacks.send(.cancelled)
        }
        
        return .success(())
    }
    
    // MARK: - Private
    
    static var emojis: [SessionVerificationEmoji] {
        [SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
         SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
         SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
         SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
         SessionVerificationEmoji(symbol: "🌏", description: "Globe")]
    }
}
