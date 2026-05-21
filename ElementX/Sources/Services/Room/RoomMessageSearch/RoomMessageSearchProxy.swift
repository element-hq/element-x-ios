//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class RoomMessageSearchProxy: RoomMessageSearchProxyProtocol {
    private let iterator: RoomSearchIteratorProtocol
    private let ownUserID: String
    private let eventStringBuilder: RoomEventStringBuilder

    init(iterator: RoomSearchIteratorProtocol,
         ownUserID: String,
         eventStringBuilder: RoomEventStringBuilder) {
        self.iterator = iterator
        self.ownUserID = ownUserID
        self.eventStringBuilder = eventStringBuilder
    }

    func loadNextResults() async -> Result<[RoomMessageSearchResult]?, RoomProxyError> {
        do {
            guard let results = try await iterator.nextEvents() else {
                return .success(nil)
            }

            return .success(results.map(buildResult))
        } catch {
            return .failure(.sdkError(error))
        }
    }

    // MARK: - Private

    private func buildResult(_ result: RoomSearchResult) -> RoomMessageSearchResult {
        let sender = TimelineItemSender(senderID: result.sender, senderProfile: result.senderProfile)
        let timestamp = Date(timeIntervalSince1970: TimeInterval(result.timestamp / 1000))
        let message = eventStringBuilder.buildAttributedString(for: result.content,
                                                               sender: sender,
                                                               isOutgoing: result.sender == ownUserID)

        return RoomMessageSearchResult(id: result.eventId,
                                       sender: sender,
                                       timestamp: timestamp,
                                       message: message)
    }
}
