//
// Copyright 2023 New Vector Ltd
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

enum AppRoute: Equatable {
    case roomList
    case room(roomID: String)
    case roomDetails(roomID: String)
    case invites
    case genericLink(url: URL)
}

enum AppRouteURLParser {
    private enum KnownHosts: String, CaseIterable {
        case elementIo = "element.io"
        case appElementIo = "app.element.io"
        case statingElementIo = "staging.element.io"
        case developElementIo = "develop.element.io"
        case mobileElementIo = "mobile.element.io"
        case callElementIo = "call.element.io"
    }
    
    static func route(from url: URL) -> AppRoute? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = urlComponents.host else {
            MXLog.error("Failed parsing URL: \(url)")
            return nil
        }
        
        guard KnownHosts.allCases.map(\.rawValue).contains(host) else {
            return .genericLink(url: url)
        }
        
        if host == KnownHosts.callElementIo.rawValue {
            return .genericLink(url: url)
        }
        
        // Deep linking not supported
//        return nil
        
        #warning("Remove this")
        return .genericLink(url: url)
    }
}
