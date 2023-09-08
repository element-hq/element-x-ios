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
            WebsiteParser(appSettings: appSettings),
            ElementCallParser()
        ]
    }
    
    func route(from url: URL) -> AppRoute? {
        for parser in urlParsers {
            if let appRoute = parser.route(from: url) {
                return appRoute
            }
        }
        
        // Fallback to a generic call link. This is temporary and will
        // be handled by a parser that checks for a specific URL scheme.
        if let host = url.host(), !urlParsers.map(\.host).contains(host) {
            return .genericCallLink(url: url)
        }
        
        MXLog.error("Failed parsing URL: \(url)")
        return nil
    }
}

/// Represents a type that can parse a `URL` into an `AppRoute`.
///
/// The following Universal Links are missing parsers.
/// - app.element.io
/// - staging.element.io
/// - develop.element.io
/// - mobile.element.io
protocol URLParser {
    var host: String { get }
    func route(from url: URL) -> AppRoute?
}

/// The parser for the element.io main website.
struct WebsiteParser: URLParser {
    let host = "element.io"
    
    var appSettings: AppSettings
    
    func route(from url: URL) -> AppRoute? {
        guard url.host() == host else { return nil }
        let pathComponents = url.pathComponents
        
        // OIDC callback URL.
        if pathComponents.count == 3, pathComponents[0] == "mobile", pathComponents[1] == "oidc" {
            return .oidcCallback(url: url)
        }
        
        return nil
    }
}

/// The parser for Element Call links. This always returns a `.genericCallLink`
struct ElementCallParser: URLParser {
    let host = "call.element.io"
    
    func route(from url: URL) -> AppRoute? {
        guard url.host() == host else { return nil }
        return .genericCallLink(url: url)
    }
}
