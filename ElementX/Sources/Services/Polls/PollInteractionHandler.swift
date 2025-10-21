//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class PollInteractionHandler: PollInteractionHandlerProtocol {
    let analyticsService: AnalyticsService
    let timelineController: TimelineControllerProtocol
    
    init(analyticsService: AnalyticsService, timelineController: TimelineControllerProtocol) {
        self.analyticsService = analyticsService
        self.timelineController = timelineController
    }
    
    func sendPollResponse(pollStartID: String, optionID: String) async -> Result<Void, Error> {
        let sendPollResponseResult = await timelineController.sendPollResponse(pollStartID: pollStartID, answers: [optionID])
        analyticsService.trackPollVote()
        
        return sendPollResponseResult.mapError { $0 }
    }
    
    func endPoll(pollStartID: String) async -> Result<Void, Error> {
        let endPollResult = await timelineController.endPoll(pollStartID: pollStartID,
                                                             text: "The poll with event id: \(pollStartID) has ended")
        analyticsService.trackPollEnd()
        return endPollResult.mapError { $0 }
    }
}
