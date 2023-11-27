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
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private var timeline: Timeline
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    #warning("AG: should we use a different task name for different TimelineProxies?")
    private let backgroundTaskName = "SendRoomEvent"
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.low_priority", qos: .utility)
    private let messageSendingDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.message_sending", qos: .userInitiated)
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.user_initiated", qos: .userInitiated)
    
    init(timeline: Timeline, backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.timeline = timeline
        self.backgroundTaskService = backgroundTaskService
    }
    
    func messageEventContent(for eventID: String) -> RoomMessageEventContentWithoutRelation? {
        try? timeline.getTimelineEventContentByEventId(eventId: eventID)
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, TimelineProxyError> {
        do {
            try await Task.dispatch(on: .global()) {
                try self.timeline.paginateBackwards(opts: .untilNumItems(eventLimit: UInt16(requestSize), items: UInt16(untilNumberOfItems), waitForToken: true))
            }
            
            return .success(())
        } catch {
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo eventID: String? = nil,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let messageContent = buildMessageContentFor(message,
                                                    html: html,
                                                    intentionalMentions: intentionalMentions.toRustMentions())
        
        return await Task.dispatch(on: messageSendingDispatchQueue) {
            do {
                if let eventID {
                    let replyItem = try self.timeline.getEventTimelineItemByEventId(eventId: eventID)
                    try self.timeline.sendReply(msg: messageContent, replyItem: replyItem)
                } else {
                    self.timeline.send(msg: messageContent)
                }
            } catch {
                return .failure(.failedSendingMessage)
            }
            return .success(())
        }
    }
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContentWithoutRelation) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self.timeline.send(msg: messageContent)
            return .success(())
        }
    }
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: lowPriorityDispatchQueue) {
            do {
                try self.timeline.sendReadReceipt(eventId: eventID)
                return .success(())
            } catch {
                return .failure(.failedSendingReadReceipt)
            }
        }
    }
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.timeline.toggleReaction(eventId: eventID, key: reaction)
                return .success(())
            } catch {
                return .failure(.failedSendingReaction)
            }
        }
    }
    
    // MARK: - Private

    private func buildMessageContentFor(_ message: String,
                                        html: String?,
                                        intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        let emoteSlashCommand = "/me "
        let isEmote: Bool = message.starts(with: emoteSlashCommand)
        
        let content: RoomMessageEventContentWithoutRelation
        if isEmote {
            let emoteMessage = String(message.dropFirst(emoteSlashCommand.count))
            
            var emoteHtml: String?
            if let html {
                emoteHtml = String(html.dropFirst(emoteSlashCommand.count))
            }
            content = buildEmoteMessageContentFor(emoteMessage, html: emoteHtml)
        } else {
            if let html {
                content = messageEventContentFromHtml(body: message, htmlBody: html)
            } else {
                content = messageEventContentFromMarkdown(md: message)
            }
        }
        return content.withMentions(mentions: intentionalMentions)
    }
    
    private func buildEmoteMessageContentFor(_ message: String, html: String?) -> RoomMessageEventContentWithoutRelation {
        if let html {
            return messageEventContentFromHtmlAsEmote(body: message, htmlBody: html)
        } else {
            return messageEventContentFromMarkdownAsEmote(md: message)
        }
    }
}
