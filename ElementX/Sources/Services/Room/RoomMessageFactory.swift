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

import Foundation
import MatrixRustSDK

struct RoomMessageFactory: RoomMessageFactoryProtocol {
    func buildRoomMessageFrom(_ message: AnyMessage) -> RoomMessageProtocol {
        if let textMessage = message.textMessage() {
            return TextRoomMessage(message: textMessage)
        } else if let imageMessage = message.imageMessage() {
            return ImageRoomMessage(message: imageMessage)
        } else if let noticeMessage = message.noticeMessage() {
            return NoticeRoomMessage(message: noticeMessage)
        } else if let emoteMessage = message.emoteMessage() {
            return EmoteRoomMessage(message: emoteMessage)
        } else {
            fatalError("One of these must exist")
        }
    }
}
