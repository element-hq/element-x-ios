//
// Copyright 2024 New Vector Ltd
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

import SwiftUI

private enum GenericCallLinkQueryParameters {
    static let appPrompt = "appPrompt"
    static let confineToRoom = "confineToRoom"
}

/// Information about how a call should be configured.
struct ElementCallConfiguration {
    enum Kind {
        case genericCallLink(URL)
        case roomCall(roomProxy: RoomProxyProtocol,
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
    init(roomProxy: RoomProxyProtocol,
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
    var callID: String {
        switch kind {
        case .genericCallLink(let url):
            url.absoluteString
        case .roomCall(let roomProxy, _, _, _, _, _):
            roomProxy.id
        }
    }
}
