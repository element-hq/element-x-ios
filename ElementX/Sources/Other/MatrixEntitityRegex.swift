//
//  MatrixEntitityRegex.swift
//  ElementX
//
//  Created by Stefan Ceriu on 26/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum MatrixEntityRegex: String {
    case homeserver
    case userId
    case roomAlias
    case roomId
    case eventId
    case groupId
    
    var rawValue: String {
        switch self {
        case .homeserver:
            return "[A-Z0-9]+((\\.|\\-)[A-Z0-9]+){0,}(:[0-9]{2,5})?"
        case .userId:
            return "@[\\x21-\\x39\\x3B-\\x7F]+:" + MatrixEntityRegex.homeserver.rawValue
        case .roomAlias:
            return "#[A-Z0-9._%#@=+-]+:" + MatrixEntityRegex.homeserver.rawValue
        case .roomId:
            return "![A-Z0-9]+:" + MatrixEntityRegex.homeserver.rawValue
        case .eventId:
            return "\\$[A-Z0-9]+:" + MatrixEntityRegex.homeserver.rawValue
        case .groupId:
            return "\\+[A-Z0-9=_\\-./]+:" + MatrixEntityRegex.homeserver.rawValue
        }
    }
}
