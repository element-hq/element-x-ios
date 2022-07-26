//
//  ClientError.swift
//  ElementX
//
//  Created by Doug on 30/06/2022.
//  Copyright © 2022 Element. All rights reserved.
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
