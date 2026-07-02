// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.

import Combine
import Foundation
import MatrixRustSDK

enum SearchServiceProxyError: Error {
    case sdkError(Error)
}

// sourcery: AutoMockable
protocol SearchServiceProxyProtocol {
    var resultsPublisher: CurrentValuePublisher<[SearchServiceResult], Never> { get }

    func setQuery(_ query: String) async -> Result<Void, SearchServiceProxyError>

    /// Loads the next page of results. No-ops if a page is already loading or the end has been reached.
    func paginate() async
}

struct SearchServiceResult {
    let roomID: String
    let eventID: String
    let sender: TimelineItemSender
    let content: TimelineEventContent
    let timestamp: Date
}
