//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

private enum GenericCallLinkQueryParameters {
    static let appPrompt = "appPrompt"
    static let confineToRoom = "confineToRoom"
}

/// Information about how a call should be configured.
struct ElementCallConfiguration {
    enum Kind {
        case genericCallLink(URL)
        case roomCall(roomProxy: JoinedRoomProxyProtocol,
                      clientProxy: ClientProxyProtocol,
                      clientID: String,
                      elementCallBaseURL: URL,
                      elementCallBaseURLOverride: URL?,
                      colorScheme: ColorScheme)
    }
    
    /// The type of call being configured i.e. whether it's an external URL or an internal room call.
    let kind: Kind
    
    /// Creates a configuration for an external call URL.
    init(genericCallLink url: URL) {
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            var fragmentQueryItems = urlComponents.fragmentQueryItems ?? []
            
            fragmentQueryItems.removeAll { $0.name == GenericCallLinkQueryParameters.appPrompt }
            fragmentQueryItems.removeAll { $0.name == GenericCallLinkQueryParameters.confineToRoom }
            
            fragmentQueryItems.append(.init(name: GenericCallLinkQueryParameters.appPrompt, value: "false"))
            fragmentQueryItems.append(.init(name: GenericCallLinkQueryParameters.confineToRoom, value: "true"))
            
            urlComponents.fragmentQueryItems = fragmentQueryItems
            
            if let adjustedURL = urlComponents.url {
                kind = .genericCallLink(adjustedURL)
            } else {
                MXLog.error("Failed adjusting URL with components: \(urlComponents)")
                kind = .genericCallLink(url)
            }
        } else {
            MXLog.error("Failed constructing URL components for url: \(url)")
            kind = .genericCallLink(url)
        }
    }
    
    /// Creates a configuration for an internal room call.
    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         clientID: String,
         elementCallBaseURL: URL,
         elementCallBaseURLOverride: URL?,
         colorScheme: ColorScheme) {
        kind = .roomCall(roomProxy: roomProxy,
                         clientProxy: clientProxy,
                         clientID: clientID,
                         elementCallBaseURL: elementCallBaseURL,
                         elementCallBaseURLOverride: elementCallBaseURLOverride,
                         colorScheme: colorScheme)
    }
    
    /// A string representing the call being configured.
    var callRoomID: String {
        switch kind {
        case .genericCallLink(let url):
            url.absoluteString
        case .roomCall(let roomProxy, _, _, _, _, _):
            roomProxy.id
        }
    }
}
