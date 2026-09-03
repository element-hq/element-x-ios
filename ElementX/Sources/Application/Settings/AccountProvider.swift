//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated enum AccountProvider: Equatable {
    /// An account provider that was input/chosen by the user.
    case generic(String)
    /// An account provider as provided by the app.
    case managed(serverName: String, baseURL: URL, canUseServerName: Bool = true)
    
    /// The account provider's string value, shown in the UI and used to build a `Client` with.
    var serverNameOrBaseURL: String {
        let serverNameOrBaseURL = switch self {
        case .generic(let serverNameOrBaseURL):
            serverNameOrBaseURL
        case .managed(let serverName, let baseURL, let canUseServerName):
            canUseServerName ? serverName : baseURL.absoluteString
        }
        
        return sanitize(serverNameOrBaseURL)
    }
    
    /// Sanitizes an address with the following rules:
    /// - Trim any whitespace.
    /// - Lowercase the address.
    /// - Removes an https scheme (treating it as implicit).
    /// - Remove any trailing slashes.
    private func sanitize(_ serverNameOrBaseURL: String) -> String {
        serverNameOrBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingPrefix("https://") // Intentionally continue to show http:// as an indicator (and for history).
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

// MARK: - Array

extension [AccountProvider] {
    /// Whether the collection includes a provider matching the given server name or base URL.
    func contains(serverName: String?, orBaseURL baseURL: URL?) -> Bool {
        contains { accountProvider in
            switch accountProvider {
            case .generic(let serverNameOrBaseURL):
                // Lower case potential user input to be safe. Full sanitisation is wrong given the scheme would be ignored.
                serverNameOrBaseURL.lowercased() == serverName || serverNameOrBaseURL.lowercased() == baseURL?.absoluteString
            case .managed(let providerServerName, let providerBaseURL, _):
                // We can ignore canUseServerName here, it's about constructing a client rather than matching.
                providerServerName == serverName || providerBaseURL == baseURL
            }
        }
    }
}
