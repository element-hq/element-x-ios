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
    case startedBackPaginating
    case finishedBackPaginating
}

enum RoomTimelineControllerAction {
    case displayVideo(videoURL: URL)
    case displayFile(fileURL: URL, title: String?)
    case none
}

enum RoomTimelineControllerError: Error {
    case generic
}

@MainActor
protocol RoomTimelineControllerProtocol {
    var roomId: String { get }
    
    var timelineItems: [RoomTimelineItemProtocol] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func processItemAppearance(_ itemId: String) async
    
    func processItemDisappearance(_ itemId: String) async

    func processItemTap(_ itemId: String) async -> RoomTimelineControllerAction
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError>
    
    func sendMessage(_ message: String) async
    
    func sendReply(_ message: String, to itemId: String) async

    func editMessage(_ newMessage: String, of itemId: String) async
    
    func sendReaction(_ reaction: String, for itemId: String) async

    func redact(_ eventID: String) async
    
    func debugDescriptionFor(_ itemId: String) -> String
}
