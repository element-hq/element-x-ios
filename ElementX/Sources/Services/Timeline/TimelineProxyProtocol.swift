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

import MatrixRustSDK

// sourcery: AutoMockable
protocol TimelineProxyProtocol {
    func messageEventContent(for eventID: String) -> RoomMessageEventContentWithoutRelation?
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, TimelineProxyError>
    func sendReadReceipt(for eventID: String) async -> Result<Void, TimelineProxyError>
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError>
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo eventID: String?,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError>
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, TimelineProxyError>
}

enum TimelineProxyError: Error, Equatable {
    case failedPaginatingBackwards
    case failedSendingMessage
    case failedSendingReaction
    case failedSendingReadReceipt
}

extension TimelineProxyProtocol {
    func sendMessage(_ message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        await sendMessage(message,
                          html: html,
                          inReplyTo: nil,
                          intentionalMentions: intentionalMentions)
    }
}
