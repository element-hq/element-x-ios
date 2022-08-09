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
}

extension AuthenticationError {
    var code: MatrixErrorCode {
        guard case let .Generic(message) = self else { return .unknown }
        
        for code in MatrixErrorCode.allCases {
            if message.contains(code.rawValue) {
                return code
            }
        }
        
        return .unknown
    }
}
