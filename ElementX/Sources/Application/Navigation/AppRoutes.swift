//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// MARK: - Routes

enum AppRoute: Hashable {
    /// An account provisioning link generated externally.
    case accountProvisioningLink(AccountProvisioningParameters)
    /// An external callback used to complete login with OIDC. This is only used when authentication
    /// requires an external app so cannot be done within the built in web authentication session.
    case oidcCallback(url: URL)
    
    /// The app's home screen.
    case roomList
    /// A room, shown as the root of the stack (popping any child rooms).
    case room(roomID: String, via: [String])
    /// The same as ``room`` but using a room alias.
    case roomAlias(String)
    /// A room, pushed as a child of any existing rooms on the stack.
    case childRoom(roomID: String, via: [String])
    /// The same as ``childRoom`` but using a room alias.
    case childRoomAlias(String)
    /// The information about a particular room.
    case roomDetails(roomID: String)
    /// The profile of a member within the current room.
    case roomMemberDetails(userID: String)
    /// An event within a room, shown as the root of the stack (popping any child rooms).
    case event(eventID: String, roomID: String, via: [String])
    /// The same as ``event`` but using a room alias.
    case eventOnRoomAlias(eventID: String, alias: String)
    /// An event within a room, either within the last child on the stack or pushing a new child if needed.
    case childEvent(eventID: String, roomID: String, via: [String])
    /// The same as ``childEvent`` but using a room alias.
    case childEventOnRoomAlias(eventID: String, alias: String)
    /// The profile of a matrix user (outside of a room).
    case userProfile(userID: String)
    /// An Element Call running in a particular room
    case call(roomID: String, isVoiceCall: Bool)
    /// The settings screen.
    case settings
    /// The setting screen for key backup.
    case chatBackupSettings
    /// An external share request e.g. from the ShareExtension
    case share(ShareExtensionPayload)
    /// The change roles screen of a room with the transfer ownership setting
    case transferOwnership(roomID: String)
    /// A thread within a room, only to be used to handle tap on notification for threaded events.
    case thread(roomID: String, threadRootEventID: String, focusEventID: String?)
    /// The global search screen
    case globalSearch
    
    /// Whether or not the route should be handled by the authentication flow.
    var isAuthenticationRoute: Bool {
        switch self {
        case .accountProvisioningLink: true
        case .oidcCallback: true
        default: false
        }
    }
}

/// The parameters parsed out of a provisioning link that can be applied to the authentication flow for a streamlined onboarding experience.
struct AccountProvisioningParameters: Hashable {
    let accountProvider: String
    let loginHint: String?
    
    enum CodingKeys: String, CodingKey {
        case accountProvider = "account_provider"
        case loginHint = "login_hint"
    }
}

struct AppRouteURLParser {
    let urlParsers: [URLParser]
    
    init(appSettings: AppSettings) {
        urlParsers = [
            AppGroupURLParser(),
            MatrixPermalinkParser(),
            ElementWebURLParser(domains: appSettings.elementWebHosts),
            AccountProvisioningURLParser(domain: appSettings.accountProvisioningHost),
            OIDCCallbackURLParser(redirectURL: appSettings.oidcRedirectURL)
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

// MARK: - URL Parsers

/// Represents a type that can parse a `URL` into an `AppRoute`.
///
/// The following Universal Links are missing parsers.
/// - mobile.element.io
protocol URLParser {
    func route(from url: URL) -> AppRoute?
}

/// The parser for routes that come from app extensions such as the Share Extension.
private struct AppGroupURLParser: URLParser {
    func route(from url: URL) -> AppRoute? {
        guard let scheme = url.scheme,
              scheme == InfoPlistReader.app.appScheme,
              url.pathComponents.last == ShareExtensionConstants.urlPath else {
            return nil
        }
        
        guard let query = url.query(percentEncoded: false),
              let queryData = query.data(using: .utf8) else {
            MXLog.error("Failed processing share parameters")
            return nil
        }
        
        do {
            let payload = try JSONDecoder().decode(ShareExtensionPayload.self, from: queryData)
            return .share(payload)
        } catch {
            MXLog.error("Failed decoding share payload with error: \(error)")
            return nil
        }
    }
}

private struct MatrixPermalinkParser: URLParser {
    func route(from url: URL) -> AppRoute? {
        guard let entity = parseMatrixEntityFrom(uri: url.absoluteString) else { return nil }
        
        switch entity.id {
        case .room(let id):
            return .room(roomID: id, via: entity.via)
        case .roomAlias(let alias):
            return .roomAlias(alias)
        case .user(let id):
            return .userProfile(userID: id)
        case .eventOnRoomId(let roomID, let eventID):
            return .event(eventID: eventID, roomID: roomID, via: entity.via)
        case .eventOnRoomAlias(let alias, let eventID):
            return .eventOnRoomAlias(eventID: eventID, alias: alias)
        }
    }
}

private struct ElementWebURLParser: URLParser {
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

/// The parser for user provisioning links.
private struct AccountProvisioningURLParser: URLParser {
    let domain: String
    
    func route(from url: URL) -> AppRoute? {
        guard url.host() == domain else { return nil }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let serverName = components.queryItems?.first(where: { $0.name == AccountProvisioningParameters.CodingKeys.accountProvider.rawValue })?.value else {
            return nil
        }
        
        let loginHint = components.queryItems?.first { $0.name == AccountProvisioningParameters.CodingKeys.loginHint.rawValue }?.value
        
        return .accountProvisioningLink(.init(accountProvider: serverName, loginHint: loginHint))
    }
}

/// The parser for the OIDC callback URL. This always returns a `.oidcCallback`.
struct OIDCCallbackURLParser: URLParser {
    let redirectURL: URL
    
    func route(from url: URL) -> AppRoute? {
        guard url.absoluteString.starts(with: redirectURL.absoluteString) else { return nil }
        return .oidcCallback(url: url)
    }
}
