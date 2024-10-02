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
}
