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

enum MatrixEntityRegex: String {
    case homeserver
    case userId
    case roomAlias
    case roomId
    case eventId
    
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
        }
    }
}
