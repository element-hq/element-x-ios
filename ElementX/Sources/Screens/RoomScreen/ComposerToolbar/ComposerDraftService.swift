//
// Copyright 2024 New Vector Ltd
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

import MatrixRustSDK

final class ComposerDraftService: ComposerDraftServiceProtocol {
    private let roomProxy: RoomProxyProtocol
    private let timelineItemfactory: RoomTimelineItemFactoryProtocol
    
    init(roomProxy: RoomProxyProtocol, timelineItemfactory: RoomTimelineItemFactoryProtocol) {
        self.roomProxy = roomProxy
        self.timelineItemfactory = timelineItemfactory
    }
    
    func saveDraft(_ draft: ComposerDraft) async {
        switch await roomProxy.saveDraft(draft) {
        case .success:
            MXLog.info("Successfully saved draft")
        case .failure(let error):
            MXLog.info("Failed to save draft: \(error)")
        }
    }
    
    func restoreDraft() async -> Result<ComposerDraft?, ComposerDraftServiceError> {
        switch await roomProxy.restoreDraft() {
        case .success(let draft):
            return .success(draft)
        case .failure(let error):
            MXLog.info("Failed to restore draft: \(error)")
            return .failure(.generic)
        }
    }
    
    func getReply(eventID: String) async -> TimelineItemReplyDetails {
        guard case let .success(replyDetails) = await roomProxy.getLoadedReplyDetails(eventID: eventID) else {
            return .error(eventID: eventID, message: "Could not load details")
        }
        
        return await timelineItemfactory.buildReplyToDetails(details: replyDetails)
    }
    
    func clearDraft() async {
        switch await roomProxy.clearDraft() {
        case .success:
            MXLog.info("Successfully cleared draft")
        case .failure(let error):
            MXLog.info("Failed to clear draft: \(error)")
        }
    }
}
