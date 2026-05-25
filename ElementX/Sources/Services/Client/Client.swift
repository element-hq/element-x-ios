//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension ClientProtocol {
    func elementWellKnown() async -> Result<Data, ClientProxyError> {
        let serverNameURLString = if let userIDServerName = try? userIdServerName() {
            "https://\(userIDServerName)"
        } else {
            server() ?? homeserver()
        }

        do {
            guard let url = URL(string: serverNameURLString)?.appending(path: "/.well-known/element/element.json") else {
                return .failure(.invalidServerName)
            }

            let data = try await getUrl(url: url.absoluteString)

            return .success(data)
        } catch {
            return .failure(.sdkError(error))
        }
    }

    /// Reads the homeserver-advertised map tile server (`tile_server.map_style_url`
    /// from the matrix client well-known) and applies it to ``AppSettings``.
    ///
    /// Clears any previously applied URL when none is advertised (or the well-known
    /// is unavailable), so each session start reflects the latest server-side
    /// configuration.
    func updateMapTilerSettings(in appSettings: AppSettings) async {
        if let url = await tileServer().flatMap({ URL(string: $0.mapStyleUrl) }) {
            appSettings.mapTilerSettings.applyRemoteValue(.url(url))
        } else {
            appSettings.mapTilerSettings.reset()
        }
    }
}
