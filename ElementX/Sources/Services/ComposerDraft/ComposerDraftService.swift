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
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineItemfactory: RoomTimelineItemFactoryProtocol
    private var volatileDraft: ComposerDraftProxy?
    
    init(roomProxy: JoinedRoomProxyProtocol, timelineItemfactory: RoomTimelineItemFactoryProtocol) {
        self.roomProxy = roomProxy
        self.timelineItemfactory = timelineItemfactory
    }
    
    func saveDraft(_ draft: ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError> {
        switch await roomProxy.saveDraft(draft.toRust) {
        case .success:
            MXLog.info("Successfully saved draft")
            return .success(())
        case .failure(let error):
            MXLog.info("Failed to save draft: \(error)")
            return .failure(.failedToSaveDraft)
        }
    }
    
    func loadDraft() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError> {
        switch await roomProxy.loadDraft() {
        case .success(let draft):
            guard let draft else {
                return .success(nil)
            }
            return .success(ComposerDraftProxy(from: draft))
        case .failure(let error):
            MXLog.info("Failed to load draft: \(error)")
            return .failure(.failedToLoadDraft)
        }
    }
    
    func getReply(eventID: String) async -> Result<TimelineItemReply, ComposerDraftServiceError> {
        switch await roomProxy.timeline.getLoadedReplyDetails(eventID: eventID) {
        case .success(let replyDetails):
            return await .success(timelineItemfactory.buildReply(details: replyDetails))
        case .failure(let error):
            MXLog.error("Could not load reply: \(error)")
            return .failure(.failedToLoadReply)
        }
    }
    
    func clearDraft() async -> Result<Void, ComposerDraftServiceError> {
        switch await roomProxy.clearDraft() {
        case .success:
            MXLog.info("Successfully cleared draft")
            return .success(())
        case .failure(let error):
            MXLog.info("Failed to clear draft: \(error)")
            return .failure(.failedToClearDraft)
        }
    }
    
    func saveVolatileDraft(_ draft: ComposerDraftProxy) {
        volatileDraft = draft
    }
    
    func loadVolatileDraft() -> ComposerDraftProxy? {
        volatileDraft
    }
    
    func clearVolatileDraft() {
        volatileDraft = nil
    }
}
