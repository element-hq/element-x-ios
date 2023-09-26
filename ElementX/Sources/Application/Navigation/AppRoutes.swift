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
    case oidcCallback(url: URL)
    case roomList
    case room(roomID: String)
    case roomDetails(roomID: String)
    case invites
    case genericCallLink(url: URL)
}

struct AppRouteURLParser {
    let urlParsers: [URLParser]
    
    init(appSettings: AppSettings) {
        urlParsers = [
            ElementAppURLParser(appSettings: appSettings),
            ElementCallURLParser()
        ]
    }
    
    func route(from url: URL) -> AppRoute? {
        for parser in urlParsers {
            if let appRoute = parser.route(from: url) {
                return appRoute
            }
        }
        
        return nil
    }
}

/// Represents a type that can parse a `URL` into an `AppRoute`.
///
/// The following Universal Links are missing parsers.
/// - app.element.io
/// - mobile.element.io
protocol URLParser {
    func route(from url: URL) -> AppRoute?
}

/// The parser for the main Element website.
struct ElementAppURLParser: URLParser {
    private let knownHosts = ["app.element.io", "staging.element.io", "develop.element.io"]
    
    let appSettings: AppSettings
    
    func route(from url: URL) -> AppRoute? {
        guard let host = url.host, knownHosts.contains(host) else {
            return nil
        }
        
        let pathComponents = url.pathComponents
        
        // OIDC callback URL.
        if pathComponents.count == 3, pathComponents[0] == "mobile", pathComponents[1] == "oidc" {
            return .oidcCallback(url: url)
        }
        
        return nil
    }
}

/// The parser for Element Call links. This always returns a `.genericCallLink`
struct ElementCallURLParser: URLParser {
    private let knownHosts = ["call.element.io"]
    private let customSchemeURLQueryParameterName = "url"
    
    func route(from url: URL) -> AppRoute? {
        // Element Call not supported, WebRTC not available
        // https://github.com/vector-im/element-x-ios/issues/1794
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return nil
        }
        
        // First try processing URLs with custom schemes
        if let scheme = url.scheme,
           scheme == InfoPlistReader.app.elementCallScheme {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            
            guard let encodedURLString = components.queryItems?.first(where: { $0.name == customSchemeURLQueryParameterName })?.value,
                  let callURL = URL(string: encodedURLString),
                  callURL.scheme == "https" // Don't allow URLs from potentially unsafe domains
            else {
                MXLog.error("Invalid custom scheme call parameters: \(url)")
                return nil
            }
            
            return .genericCallLink(url: callURL)
        }
        
        // Otherwise try to interpret it as an universal link
        guard let host = url.host, knownHosts.contains(host) else {
            return nil
        }
        
        return .genericCallLink(url: url)
    }
}
