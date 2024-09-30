//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension URLSession {
    /// The same as `data(for:delegate:)` but with an additional immediate retry if the first attempt fails.
    func dataWithRetry(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let firstTryResult = try? await data(for: request, delegate: delegate) {
            return firstTryResult
        }
        
        return try await data(for: request, delegate: delegate)
    }
}
