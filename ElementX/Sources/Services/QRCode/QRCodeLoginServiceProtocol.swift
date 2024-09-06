//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

import MatrixRustSDK

enum QRCodeLoginServiceError: Error {
    case failedLoggingIn
    case invalidQRCode
    case cancelled
    case connectionInsecure
    case declined
    case linkingNotSupported
    case expired
    case deviceNotSupported
    case deviceNotSignedIn
    case unknown
}

// sourcery: AutoMockable
protocol QRCodeLoginServiceProtocol {
    var qrLoginProgressPublisher: AnyPublisher<QrLoginProgress, Never> { get }
    
    func loginWithQRCode(data: Data) async -> Result<UserSessionProtocol, QRCodeLoginServiceError>
}
