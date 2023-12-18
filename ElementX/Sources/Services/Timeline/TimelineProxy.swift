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

import Combine
import Foundation
import MatrixRustSDK

final class TimelineProxy: TimelineProxyProtocol {
    private let timeline: Timeline
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    private let backgroundTaskName = "SendRoomEvent"
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.low_priority", qos: .utility)
    private let messageSendingDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.message_sending", qos: .userInitiated)
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.user_initiated", qos: .userInitiated)
    
    private var backPaginationStateObservationToken: TaskHandle?
    private var roomTimelineObservationToken: TaskHandle?
    private var timelineListener: RoomTimelineListener?
   
    private let backPaginationStateSubject = PassthroughSubject<BackPaginationStatus, Never>()
    private let timelineUpdatesSubject = PassthroughSubject<[TimelineDiff], Never>()
   
    private(set) var timelineStartReached = false
    
    private let actionsSubject = PassthroughSubject<TimelineProxyAction, Never>()
    var actions: AnyPublisher<TimelineProxyAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
   
    private var innerTimelineProvider: RoomTimelineProviderProtocol!
    var timelineProvider: RoomTimelineProviderProtocol {
        innerTimelineProvider
    }
    
    var hasPendingUpdatesSubscription: Bool {
        innerTimelineProvider != nil
    }
    
    deinit {
        backPaginationStateObservationToken?.cancel()
        roomTimelineObservationToken?.cancel()
    }
    
    init(timeline: Timeline, backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.timeline = timeline
        self.backgroundTaskService = backgroundTaskService
    }
    
    func subscribeForUpdates() async {
        guard innerTimelineProvider == nil else {
            MXLog.warning("Timeline already subscribed for updates")
            return
        }
        
        let timelineListener = RoomTimelineListener { [weak self] timelineDiffs in
            self?.timelineUpdatesSubject.send(timelineDiffs)
        }
        
        self.timelineListener = timelineListener
        
        let result = await timeline.addListener(listener: timelineListener)
        roomTimelineObservationToken = result.itemsStream
        
        subscribeToBackpagination()
        
        innerTimelineProvider = await RoomTimelineProvider(currentItems: result.items,
                                                           updatePublisher: timelineUpdatesSubject.eraseToAnyPublisher(),
                                                           backPaginationStatePublisher: backPaginationStateSubject.eraseToAnyPublisher())
    }
    
    func cancelSend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self.timeline.cancelSend(txnId: transactionID)
        }
    }
    
    func editMessage(_ message: String,
                     html: String,
                     original eventID: String,
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
                let originalEvent = try self.timeline.getEventTimelineItemByEventId(eventId: eventID)
                try self.timeline.edit(newContent: messageContent, editItem: originalEvent)
                
                return .success(())
            } catch {
                return .failure(.failedEditingMessage)
            }
        }
    }
    
    func fetchDetails(for eventID: String) {
        Task {
            await Task.dispatch(on: .global()) {
                do {
                    MXLog.info("Fetching event details for \(eventID)")
                    try self.timeline.fetchDetailsForEvent(eventId: eventID)
                } catch {
                    MXLog.error("Failed fetching event details for \(eventID) with error: \(error)")
                }
            }
        }
    }
    
    func messageEventContent(for eventID: String) -> RoomMessageEventContentWithoutRelation? {
        try? timeline.getTimelineEventContentByEventId(eventId: eventID)
    }
    
    func paginateBackwards(requestSize: UInt) async -> Result<Void, TimelineProxyError> {
        do {
            try await Task.dispatch(on: .global()) {
                try self.timeline.paginateBackwards(opts: .simpleRequest(eventLimit: UInt16(requestSize), waitForToken: true))
            }
            
            return .success(())
        } catch {
            return .failure(.failedPaginatingBackwards)
        }
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
    
    func retryDecryption(for sessionID: String) async {
        await Task.dispatch(on: .global()) { [weak self] in
            self?.timeline.retryDecryption(sessionIds: [sessionID])
        }
    }
    
    func retrySend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self.timeline.retrySend(txnId: transactionID)
        }
    }
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = timeline.sendAudio(url: url.path(percentEncoded: false), audioInfo: audioInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        actionsSubject.send(.sentMessage)
        
        return .success(())
    }
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = timeline.sendFile(url: url.path(percentEncoded: false), fileInfo: fileInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        actionsSubject.send(.sentMessage)
        
        return .success(())
    }
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = timeline.sendImage(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), imageInfo: imageInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        actionsSubject.send(.sentMessage)
        
        return .success(())
    }
    
    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self.timeline.sendLocation(body: body,
                                       geoUri: geoURI.string,
                                       description: description,
                                       zoomLevel: zoomLevel,
                                       assetType: assetType)
            
            self.actionsSubject.send(.sentMessage)
            
            return .success(())
        }
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = timeline.sendVideo(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), videoInfo: videoInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        actionsSubject.send(.sentMessage)
        
        return .success(())
    }
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [UInt16],
                          progressSubject: CurrentValueSubject<Double, Never>?,
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, TimelineProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = timeline.sendVoiceMessage(url: url.path(percentEncoded: false), audioInfo: audioInfo, waveform: waveform, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        actionsSubject.send(.sentMessage)
        
        return .success(())
    }
    
    func sendMessage(_ message: String,
                     html: String,
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
            
            self.actionsSubject.send(.sentMessage)
            
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
            
            self.actionsSubject.send(.sentMessage)
            
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
    
    // MARK: - Polls

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                try self.timeline.createPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind))
                
                self.actionsSubject.send(.sentMessage)
                
                return .success(())
            } catch {
                MXLog.error("Failed creating a poll: \(error)")
                return .failure(.failedCreatingPoll)
            }
        }
    }
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  pollKind: Poll.Kind) async -> Result<Void, TimelineProxyError> {
        do {
            let originalEvent = try await Task.dispatch(on: .global()) {
                try self.timeline.getEventTimelineItemByEventId(eventId: eventID)
            }
            return try await .success(timeline.editPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind), editItem: originalEvent))
        } catch {
            MXLog.error("Failed editing the poll: \(error), eventID: \(eventID)")
            return .failure(.failedEditingPoll)
        }
    }
    
    func endPoll(pollStartID: String, text: String) async -> Result<Void, TimelineProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.timeline.endPoll(pollStartId: pollStartID, text: text))
            } catch {
                MXLog.error("Failed ending a poll: \(error), pollStartID: \(pollStartID)")
                return .failure(.failedEndingPoll)
            }
        }
    }

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, TimelineProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.timeline.sendPollResponse(pollStartId: pollStartID, answers: answers))
            } catch {
                MXLog.error("Failed sending a poll vote: \(error), pollStartID: \(pollStartID)")
                return .failure(.failedSendingPollResponse)
            }
        }
    }
    
    // MARK: - Private
    
    private func buildMessageContentFor(_ message: String,
                                        html: String,
                                        intentionalMentions: Mentions) -> RoomMessageEventContentWithoutRelation {
        let emoteSlashCommand = "/me "
        let isEmote: Bool = message.starts(with: emoteSlashCommand)
        
        let content: RoomMessageEventContentWithoutRelation
        if isEmote {
            let emoteMessage = String(message.dropFirst(emoteSlashCommand.count))
            let emoteHtml = String(html.dropFirst(emoteSlashCommand.count))
            content = buildEmoteMessageContentFor(emoteMessage, html: emoteHtml)
        } else {
            content = messageEventContentFromHtml(body: message, htmlBody: html)
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
    
    private func subscribeToBackpagination() {
        let listener = RoomBackpaginationStatusListener { [weak self] status in
            if status == .timelineStartReached {
                self?.timelineStartReached = true
            }
            self?.backPaginationStateSubject.send(status)
        }
        do {
            backPaginationStateObservationToken = try timeline.subscribeToBackPaginationStatus(listener: listener)
        } catch {
            MXLog.error("Failed to subscribe to back pagination state with error: \(error)")
        }
    }
}

private final class RoomTimelineListener: TimelineListener {
    private let onUpdateClosure: ([TimelineDiff]) -> Void
   
    init(_ onUpdateClosure: @escaping ([TimelineDiff]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(diff: [TimelineDiff]) {
        onUpdateClosure(diff)
    }
}

private final class RoomBackpaginationStatusListener: BackPaginationStatusListener {
    private let onUpdateClosure: (BackPaginationStatus) -> Void

    init(_ onUpdateClosure: @escaping (BackPaginationStatus) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }

    func onUpdate(status: BackPaginationStatus) {
        onUpdateClosure(status)
    }
}

private final class UploadProgressListener: ProgressWatcher {
    private let onUpdateClosure: (Double) -> Void
    
    init(_ onUpdateClosure: @escaping (Double) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func transmissionProgress(progress: TransmissionProgress) {
        DispatchQueue.main.async { [weak self] in
            self?.onUpdateClosure(Double(progress.current) / Double(progress.total))
        }
    }
}

private extension MatrixRustSDK.PollKind {
    init(pollKind: Poll.Kind) {
        switch pollKind {
        case .disclosed:
            self = .disclosed
        case .undisclosed:
            self = .undisclosed
        }
    }
}
