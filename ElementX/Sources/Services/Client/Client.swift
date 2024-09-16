//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension ClientProtocol {
    func getElementWellKnown() async -> Result<MatrixRustSDK.ElementWellKnown, ClientProxyError> {
        do {
            let serverName = if let userIDServerName = try? userIdServerName() {
                "https://\(userIDServerName)"
            } else {
                server()
            }
            
            guard let serverName,
                  let url = URL(string: serverName)?.appending(path: "/.well-known/element/element.json") else {
                return .failure(.invalidServerName)
            }
            
            let response = try await getUrl(url: url.absoluteString)
            let wellKnown = try makeElementWellKnown(string: response)
            return .success(wellKnown)
        } catch {
            return .failure(.sdkError(error))
        }
    }
}
