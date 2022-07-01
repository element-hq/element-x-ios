//
//  SessionVerificationControllerProxyProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 07/06/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum SessionVerificationControllerProxyError: Error {
    case failedRequestingVerification
    case failedApprovingVerification
    case failedDecliningVerification
    case failedCancellingVerification
}

enum SessionVerificationControllerProxyCallback {
    case receivedVerificationData([SessionVerificationEmoji])
    case finished
    case cancelled
    case failed
}

struct SessionVerificationEmoji: Hashable {
    let symbol: String
    let description: String
}

protocol SessionVerificationControllerProxyProtocol {
    var callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> { get }
    
    var isVerified: Bool { get }
        
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError>
}
