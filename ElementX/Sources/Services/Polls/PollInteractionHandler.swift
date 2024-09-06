//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class PollInteractionHandler: PollInteractionHandlerProtocol {
    let analyticsService: AnalyticsService
    let roomProxy: JoinedRoomProxyProtocol
    
    init(analyticsService: AnalyticsService, roomProxy: JoinedRoomProxyProtocol) {
        self.analyticsService = analyticsService
        self.roomProxy = roomProxy
    }
    
    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        let sendPollResponseResult = await roomProxy.timeline.sendPollResponse(pollStartID: pollStartID, answers: [optionID])
        analyticsService.trackPollVote()

        return sendPollResponseResult.mapError { $0 }
    }
    
    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        let endPollResult = await roomProxy.timeline.endPoll(pollStartID: pollStartID,
                                                             text: "The poll with event id: \(pollStartID) has ended")
        analyticsService.trackPollEnd()
        return endPollResult.mapError { $0 }
    }
}
