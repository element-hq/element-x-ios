//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

enum RoomTimelineControllerCallback {
    case updatedTimelineItems(timelineItems: [RoomTimelineItemProtocol], isSwitchingTimelines: Bool)
    case paginationState(PaginationState)
    case isLive(Bool)
}

enum RoomTimelineControllerAction {
    case displayMediaFile(file: MediaFileHandleProxy, title: String?)
    case displayLocation(body: String, geoURI: GeoURI, description: String?)
    case none
}

enum RoomTimelineControllerError: Error {
    case generic
    case eventNotFound
}

@MainActor
protocol RoomTimelineControllerProtocol {
    var roomID: String { get }
    var timelineKind: TimelineKind { get }
    
    var timelineItems: [RoomTimelineItemProtocol] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) async
    
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, RoomTimelineControllerError>
    func focusLive()
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, RoomTimelineControllerError>
    func paginateForwards(requestSize: UInt16) async -> Result<Void, RoomTimelineControllerError>
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo itemID: TimelineItemIdentifier?,
                     intentionalMentions: IntentionalMentions) async
    
    func edit(_ timelineItemID: TimelineItemIdentifier,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async
    
    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async

    func redact(_ itemID: TimelineItemIdentifier) async
    
    func pin(eventID: String) async
    
    func unpin(eventID: String) async
    
    func messageEventContent(for itemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation?
    
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo
    
    func retryDecryption(for sessionID: String) async
    
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date?
}

extension RoomTimelineControllerProtocol {
    func sendMessage(_ message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async {
        await sendMessage(message,
                          html: html,
                          inReplyTo: nil,
                          intentionalMentions: intentionalMentions)
    }
}
