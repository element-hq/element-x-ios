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

extension AuthenticationError {
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
