//
// Copyright 2022 New Vector Ltd
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

import Combine
import Foundation
import UIKit

enum RoomTimelineControllerCallback {
    case updatedTimelineItems
    case updatedTimelineItem(_ itemId: String)
    case canBackPaginate(Bool)
    case isBackPaginating(Bool)
}

enum RoomTimelineControllerAction {
    case displayVideo(videoURL: URL, title: String?)
    case displayFile(fileURL: URL, title: String?)
    case none
}

enum RoomTimelineControllerError: Error {
    case generic
}

@MainActor
protocol RoomTimelineControllerProtocol {
    var roomID: String { get }
    
    var timelineItems: [RoomTimelineItemProtocol] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func processItemAppearance(_ itemID: String) async
    
    func processItemDisappearance(_ itemID: String) async

    func processItemTap(_ itemID: String) async -> RoomTimelineControllerAction
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError>
    
    func markRoomAsRead() async -> Result<Void, RoomTimelineControllerError>
    
    func sendMessage(_ message: String, inReplyTo itemID: String?) async

    func editMessage(_ newMessage: String, original itemID: String) async
    
    func sendReaction(_ reaction: String, to itemID: String) async

    func redact(_ itemID: String) async

    func reportContent(_ itemID: String, reason: String?) async
    
    func debugDescription(for itemID: String) -> String
    
    func retryDecryption(for sessionID: String) async
}

extension RoomTimelineControllerProtocol {
    func sendMessage(_ message: String) async {
        await sendMessage(message, inReplyTo: nil)
    }
}
