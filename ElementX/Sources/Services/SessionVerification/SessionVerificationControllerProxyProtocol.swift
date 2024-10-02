//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum SessionVerificationControllerProxyError: Error {
    case failedRequestingVerification
    case failedStartingSasVerification
    case failedApprovingVerification
    case failedDecliningVerification
    case failedCancellingVerification
}

enum SessionVerificationControllerProxyCallback {
    case acceptedVerificationRequest
    case startedSasVerification
    case receivedVerificationData([SessionVerificationEmoji])
    case finished
    case cancelled
    case failed
}

struct SessionVerificationEmoji: Hashable {
    let symbol: String
    let description: String
    
    var localizedDescription: String {
        SASL10n.localizedDescription(for: description.lowercased())
    }
}

// sourcery: AutoMockable
protocol SessionVerificationControllerProxyProtocol {
    var callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> { get }
        
    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError>
    
    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError>
}
