//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final class ComposerDraftService: ComposerDraftServiceProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let threadRootEventID: String?
    private let timelineItemfactory: RoomTimelineItemFactoryProtocol
    private var volatileDraft: ComposerDraftProxy?
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineItemfactory: RoomTimelineItemFactoryProtocol,
         threadRootEventID: String?) {
        self.roomProxy = roomProxy
        self.threadRootEventID = threadRootEventID
        self.timelineItemfactory = timelineItemfactory
    }
    
    func saveDraft(_ draft: ComposerDraftProxy) async -> Result<Void, ComposerDraftServiceError> {
        switch await roomProxy.saveDraft(draft.toRust, threadRootEventID: threadRootEventID) {
        case .success:
            MXLog.info("Successfully saved draft")
            return .success(())
        case .failure(let error):
            MXLog.info("Failed to save draft: \(error)")
            return .failure(.failedToSaveDraft)
        }
    }
    
    func loadDraft() async -> Result<ComposerDraftProxy?, ComposerDraftServiceError> {
        switch await roomProxy.loadDraft(threadRootEventID: threadRootEventID) {
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
            return .success(timelineItemfactory.buildTimelineItemReply(replyDetails))
        case .failure(let error):
            MXLog.error("Could not load reply: \(error)")
            return .failure(.failedToLoadReply)
        }
    }
    
    func clearDraft() async -> Result<Void, ComposerDraftServiceError> {
        switch await roomProxy.clearDraft(threadRootEventID: threadRootEventID) {
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
