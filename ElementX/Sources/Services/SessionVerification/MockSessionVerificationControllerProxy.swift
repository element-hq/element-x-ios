//
//  MockSessionVerificationControllerProxy.swift
//  ElementX
//
//  Created by Stefan Ceriu on 07/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK
import Combine

struct MockSessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol {
    var callbacks = PassthroughSubject<SessionVerificationControllerProxyCallback, Never>()
    
    var isVerified: Bool = true
    
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        
        callbacks.send(.receivedVerificationData(emojis))
        
        return .success(())
    }
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        return .success(())
    }
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        return .success(())
    }
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        return .success(())
    }
    
    // MARK: - Private
    
    var emojis: [SessionVerificationEmoji] {
        [SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
         SessionVerificationEmoji(symbol: "🐘", description: "Elephant"),
         SessionVerificationEmoji(symbol: "🦋", description: "Butterfly"),
         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
         SessionVerificationEmoji(symbol: "🎂", description: "Cake"),
         SessionVerificationEmoji(symbol: "🏁", description: "Flag"),
         SessionVerificationEmoji(symbol: "🌏", description: "Globe")
        ]
    }
}
