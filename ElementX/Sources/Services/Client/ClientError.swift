//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum MatrixErrorCode: String, CaseIterable {
    case unknown = "M_UNKNOWN"
    case userDeactivated = "M_USER_DEACTIVATED"
    case forbidden = "M_FORBIDDEN"
    case fileTooLarge = "M_TOO_LARGE"
}

extension ClientError {
    var code: MatrixErrorCode {
        guard case let .Generic(message) = self else { return .unknown }
        
        guard let first = MatrixErrorCode.allCases.first(where: { message.contains($0.rawValue) }) else {
            return .unknown
        }

        return first
    }
    
    /// Whether or not the error is related to the sliding sync proxy being full.
    ///
    /// This is a temporary error whilst we scale the backend infrastructure.
    var isElementWaitlist: Bool {
        guard case let .Generic(message) = self else { return false }
        return message.contains("IO_ELEMENT_X_WAIT_LIST")
    }
}
