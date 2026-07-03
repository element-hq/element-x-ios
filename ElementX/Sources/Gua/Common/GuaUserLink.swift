//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// GUA FORK: Builds the user-facing share link for a Gua account.
///
/// Element's default `matrixToUserPermalink` produces a `https://matrix.to/#/@user:homeserver`
/// URL, which both surfaces the homeserver and points off-brand. Gua links instead live on the
/// brand host and carry only the local part of the MXID, so the homeserver is never exposed:
///
///     @alice:dev.local  ->  https://gua.global/u/alice
///
/// This is only for sharing/inviting. In-app mention parsing and pills still use `matrix.to`.
enum GuaUserLink {
    /// Builds `https://<brandHost>/u/<localpart>` for a Matrix user ID, where `localpart` is the
    /// part between `@` and `:`. Returns `nil` for a malformed ID.
    static func url(for userID: String) -> URL? {
        guard userID.hasPrefix("@") else { return nil }

        let localpart = userID.dropFirst().prefix { $0 != ":" }
        guard !localpart.isEmpty else { return nil }

        // The development link host can carry a port (e.g. "localhost:8008"). Parse the whole
        // authority instead of assigning it to `URLComponents.host`, which rejects the colon
        // and would yield a nil URL.
        guard var components = URLComponents(string: "https://\(GuaDeployment.current.linkHost)") else { return nil }
        components.path = "/u/\(localpart)"
        return components.url
    }
}
