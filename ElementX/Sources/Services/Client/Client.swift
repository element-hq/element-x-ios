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
}
