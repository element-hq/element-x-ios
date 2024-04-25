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
import MatrixRustSDK

enum AppRoute: Equatable {
    /// The callback used to complete login with OIDC.
    case oidcCallback(url: URL)
    /// The app's home screen.
    case roomList
    /// A room, shown as the root of the stack (popping any child rooms).
    case room(roomID: String)
    /// The same as ``room`` but using a room alias.
    case roomAlias(String)
    /// A room, pushed as a child of any existing rooms on the stack.
    case childRoom(roomID: String)
    /// The same as ``childRoom`` but using a room alias.
    case childRoomAlias(String)
    /// The information about a particular room.
    case roomDetails(roomID: String)
    /// The profile of a member within the current room.
    case roomMemberDetails(userID: String)
    /// An event within a room, shown as the root of the stack (popping any child rooms).
    case event(roomID: String, eventID: String)
    /// The same as ``event`` but using a room alias.
    case eventOnRoomAlias(alias: String, eventID: String)
    /// An event within a room, either within the last child on the stack or pushing a new child if needed.
    case childEvent(roomID: String, eventID: String)
    /// The same as ``childEvent`` but using a room alias.
    case childEventOnRoomAlias(alias: String, eventID: String)
    /// The profile of a matrix user (outside of a room).
    case userProfile(userID: String)
    /// An Element Call link generated outside of a chat room.
    case genericCallLink(url: URL)
    /// The settings screen.
    case settings
    /// The setting screen for key backup.
    case chatBackupSettings
}

struct AppRouteURLParser {
    let urlParsers: [URLParser]
    
    init(appSettings: AppSettings) {
        urlParsers = [
            MatrixPermalinkParser(),
            ElementWebURLParser(domains: appSettings.elementWebHosts),
            OIDCCallbackURLParser(appSettings: appSettings),
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
/// - mobile.element.io
protocol URLParser {
    func route(from url: URL) -> AppRoute?
}

/// The parser for the OIDC callback URL. This always returns a `.oidcCallback`.
struct OIDCCallbackURLParser: URLParser {
    let appSettings: AppSettings
    
    func route(from url: URL) -> AppRoute? {
        guard url.absoluteString.starts(with: appSettings.oidcRedirectURL.absoluteString) else { return nil }
        return .oidcCallback(url: url)
    }
}

/// The parser for Element Call links. This always returns a `.genericCallLink`.
struct ElementCallURLParser: URLParser {
    private let knownHosts = ["call.element.io"]
    private let customSchemeURLQueryParameterName = "url"
    
    func route(from url: URL) -> AppRoute? {
        // Element Call not supported, WebRTC not available
        // https://github.com/element-hq/element-x-ios/issues/1794
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

struct MatrixPermalinkParser: URLParser {
    func route(from url: URL) -> AppRoute? {
        switch parseMatrixEntityFrom(uri: url.absoluteString)?.id {
        case .room(let id):
            return .room(roomID: id)
        case .roomAlias(let alias):
            return .roomAlias(alias)
        case .user(let id):
            return .userProfile(userID: id)
        case .eventOnRoomId(let roomID, let eventID):
            // return .event(roomID: roomID, eventID: eventID)
            return nil
        case .eventOnRoomAlias(let alias, let eventID):
            // return .eventOnRoomAlias(alias: alias, eventID: eventID)
            return nil
        default:
            return nil
        }
    }
}

struct ElementWebURLParser: URLParser {
    let domains: [String]
    let paths = ["room", "user"]
    
    private let permalinkParser = MatrixPermalinkParser()
    
    func route(from url: URL) -> AppRoute? {
        guard let matrixToURL = buildMatrixToURL(from: url) else { return nil }
        return permalinkParser.route(from: matrixToURL)
    }
    
    private func buildMatrixToURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        
        for domain in domains where domain == url.host {
            components.host = "matrix.to"
            for path in paths {
                components.fragment?.replace("/\(path)", with: "")
            }
            
            guard let matrixToURL = components.url else { continue }
            return matrixToURL
        }
        
        return url
    }
}
