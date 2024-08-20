//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
