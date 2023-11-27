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

import MatrixRustSDK

class RoomProxy: RoomProxyProtocol {
    private let roomListItem: RoomListItemProtocol
    private let room: RoomProtocol
    private let _timeline: Timeline
    let timeline: TimelineProxyProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let backgroundTaskName = "SendRoomEvent"
    
    private let messageSendingDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.message_sending", qos: .userInitiated)
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.user_initiated", qos: .userInitiated)
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.low_priority", qos: .utility)
    
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    
    private(set) var displayName: String?
    
    private var roomTimelineObservationToken: TaskHandle?
    private var backPaginationStateObservationToken: TaskHandle?
    private var roomInfoObservationToken: TaskHandle?

    private let backPaginationStateSubject = PassthroughSubject<BackPaginationStatus, Never>()
    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    var members: CurrentValuePublisher<[RoomMemberProxyProtocol], Never> {
        membersSubject.asCurrentValuePublisher()
    }
    
    private var timelineListener: RoomTimelineListener?
    
    private let timelineUpdatesSubject = PassthroughSubject<[TimelineDiff], Never>()
        
    private let stateUpdatesSubject = PassthroughSubject<Void, Never>()
    var stateUpdatesPublisher: AnyPublisher<Void, Never> {
        stateUpdatesSubject.eraseToAnyPublisher()
    }
    
    var innerTimelineProvider: RoomTimelineProviderProtocol!
    var timelineProvider: RoomTimelineProviderProtocol {
        innerTimelineProvider
    }

    var ownUserID: String {
        room.ownUserId()
    }

    deinit {
        roomTimelineObservationToken?.cancel()
        backPaginationStateObservationToken?.cancel()
        roomListItem.unsubscribe()
    }

    init(roomListItem: RoomListItemProtocol,
         room: RoomProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) async {
        self.roomListItem = roomListItem
        self.room = room
        self.backgroundTaskService = backgroundTaskService
        _timeline = await room.timeline()
        timeline = TimelineProxy(timeline: _timeline, backgroundTaskService: backgroundTaskService)
        
        Task {
            await fetchMembers()
            await updateMembers()
        }
    }
    
    func subscribeForUpdates() async {
        guard innerTimelineProvider == nil else {
            MXLog.warning("Room already subscribed for updates")
            return
        }
        
        let settings = RoomSubscription(requiredState: [RequiredState(key: "m.room.name", value: ""),
                                                        RequiredState(key: "m.room.topic", value: ""),
                                                        RequiredState(key: "m.room.avatar", value: ""),
                                                        RequiredState(key: "m.room.canonical_alias", value: ""),
                                                        RequiredState(key: "m.room.join_rules", value: "")],
                                        timelineLimit: UInt32(SlidingSyncConstants.defaultTimelineLimit))
        roomListItem.subscribe(settings: settings)
        
        let timelineListener = RoomTimelineListener { [weak self] timelineDiffs in
            self?.timelineUpdatesSubject.send(timelineDiffs)
            
            // Workaround for subscribeToRoomStateUpdates creating problems in the timeline
            // https://github.com/matrix-org/matrix-rust-sdk/issues/2488
            self?.stateUpdatesSubject.send()
        }
        
        self.timelineListener = timelineListener
        
        let result = await room.timeline().addListener(listener: timelineListener)
        roomTimelineObservationToken = result.itemsStream
        
        subscribeToBackpagination()
        
        // subscribeToRoomStateUpdates()
        
        innerTimelineProvider = await RoomTimelineProvider(currentItems: result.items,
                                                           updatePublisher: timelineUpdatesSubject.eraseToAnyPublisher(),
                                                           backPaginationStatePublisher: backPaginationStateSubject.eraseToAnyPublisher())
    }

    lazy var id: String = room.id()
    
    var name: String? {
        roomListItem.name()
    }
        
    var topic: String? {
        room.topic()
    }
    
    var isJoined: Bool {
        room.membership() == .joined
    }
    
    var membership: Membership {
        room.membership()
    }
    
    var isDirect: Bool {
        room.isDirect()
    }
    
    var isPublic: Bool {
        room.isPublic()
    }
    
    var isSpace: Bool {
        room.isSpace()
    }
    
    var isEncrypted: Bool {
        (try? room.isEncrypted()) ?? false
    }
    
    var isTombstoned: Bool {
        room.isTombstoned()
    }
    
    var hasOngoingCall: Bool {
        room.hasActiveRoomCall()
    }
    
    var canonicalAlias: String? {
        room.canonicalAlias()
    }
    
    var alternativeAliases: [String] {
        room.alternativeAliases()
    }
    
    var hasUnreadNotifications: Bool {
        roomListItem.hasUnreadNotifications()
    }
    
    var avatarURL: URL? {
        roomListItem.avatarUrl().flatMap(URL.init(string:))
    }

    var invitedMembersCount: Int {
        Int(room.invitedMembersCount())
    }

    var joinedMembersCount: Int {
        Int(room.joinedMembersCount())
    }
    
    var activeMembersCount: Int {
        Int(room.activeMembersCount())
    }

    func loadAvatarURLForUserId(_ userId: String) async -> Result<URL?, RoomProxyError> {
        do {
            guard let urlString = try await Task.dispatch(on: lowPriorityDispatchQueue, {
                try self.room.memberAvatarUrl(userId: userId)
            }) else {
                return .success(nil)
            }
            
            guard let avatarURL = URL(string: urlString) else {
                MXLog.error("Invalid avatar URL string: \(String(describing: urlString))")
                return .failure(.failedRetrievingMemberAvatarURL)
            }
            
            return .success(avatarURL)
        } catch {
            return .failure(.failedRetrievingMemberAvatarURL)
        }
    }
    
    func loadDisplayNameForUserId(_ userId: String) async -> Result<String?, RoomProxyError> {
        do {
            let displayName = try await Task.dispatch(on: lowPriorityDispatchQueue) {
                try self.room.memberDisplayName(userId: userId)
            }
            return .success(displayName)
        } catch {
            return .failure(.failedRetrievingMemberDisplayName)
        }
    }
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self._timeline.toggleReaction(eventId: eventID, key: reaction)
                return .success(())
            } catch {
                return .failure(.failedSendingReaction)
            }
        }
    }
    
    func sendImage(url: URL,
                   thumbnailURL: URL,
                   imageInfo: ImageInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = _timeline.sendImage(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), imageInfo: imageInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = _timeline.sendVideo(url: url.path(percentEncoded: false), thumbnailUrl: thumbnailURL.path(percentEncoded: false), videoInfo: videoInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = _timeline.sendAudio(url: url.path(percentEncoded: false), audioInfo: audioInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendVoiceMessage(url: URL,
                          audioInfo: AudioInfo,
                          waveform: [UInt16],
                          progressSubject: CurrentValueSubject<Double, Never>?,
                          requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = _timeline.sendVoiceMessage(url: url.path(percentEncoded: false), audioInfo: audioInfo, waveform: waveform, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: @MainActor (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = _timeline.sendFile(url: url.path(percentEncoded: false), fileInfo: fileInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        await requestHandle(handle)
        
        do {
            try await handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }

    func sendLocation(body: String,
                      geoURI: GeoURI,
                      description: String?,
                      zoomLevel: UInt8?,
                      assetType: AssetType?) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: messageSendingDispatchQueue) {
            .success(self._timeline.sendLocation(body: body,
                                                 geoUri: geoURI.string,
                                                 description: description,
                                                 zoomLevel: zoomLevel,
                                                 assetType: assetType))
        }
    }

    func retrySend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self._timeline.retrySend(txnId: transactionID)
        }
    }

    func cancelSend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: messageSendingDispatchQueue) {
            self._timeline.cancelSend(txnId: transactionID)
        }
    }
    
    func editMessage(_ message: String,
                     html: String?,
                     original eventID: String,
                     intentionalMentions: IntentionalMentions) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let messageContent = buildMessageContentFor(message,
                                                    html: html,
                                                    intentionalMentions: intentionalMentions.toRustMentions())
        
        return await Task.dispatch(on: messageSendingDispatchQueue) {
            do {
                let originalEvent = try self._timeline.getEventTimelineItemByEventId(eventId: eventID)
                try self._timeline.edit(newContent: messageContent, editItem: originalEvent)
                return .success(())
            } catch {
                return .failure(.failedEditingMessage)
            }
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.redact(eventId: eventID, reason: nil)
                return .success(())
            } catch {
                return .failure(.failedRedactingEvent)
            }
        }
    }

    func reportContent(_ eventID: String, reason: String?) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.reportContent(eventId: eventID, score: nil, reason: reason)
                return .success(())
            } catch {
                return .failure(.failedReportingContent)
            }
        }
    }

    func updateMembers() async {
        do {
            let membersIterator = try await room.members()
            guard let members = membersIterator.nextChunk(chunkSize: membersIterator.len()) else {
                return
            }
            
            let roomMembersProxies = members.map {
                RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
            }
            
            membersSubject.value = roomMembersProxies
        } catch {
            return
        }
    }

    func getMember(userID: String) async -> Result<RoomMemberProxyProtocol, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        do {
            let member = try await room.member(userId: userID)
            return .success(RoomMemberProxy(member: member, backgroundTaskService: backgroundTaskService))
        } catch {
            return .failure(.failedRetrievingMember)
        }
    }
    
    func ignoreUser(_ userID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.ignoreUser(userId: userID)
                return .success(())
            } catch {
                return .failure(.failedReportingContent)
            }
        }
    }

    func retryDecryption(for sessionID: String) async {
        await Task.dispatch(on: .global()) { [weak self] in
            self?._timeline.retryDecryption(sessionIds: [sessionID])
        }
    }

    func leaveRoom() async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: .global()) {
            do {
                try self.room.leave()
                return .success(())
            } catch {
                MXLog.error("Failed to leave the room: \(error)")
                return .failure(.failedLeavingRoom)
            }
        }
    }
    
    func inviter() async -> RoomMemberProxyProtocol? {
        let inviter = await Task.dispatch(on: .global()) {
            self.room.inviter()
        }
        
        return inviter.map {
            RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
        }
    }
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.leave())
            } catch {
                return .failure(.failedRejectingInvite)
            }
        }
    }
    
    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                try self.room.join()
                return .success(())
            } catch {
                return .failure(.failedAcceptingInvite)
            }
        }
    }
    
    func fetchDetails(for eventID: String) {
        Task {
            await Task.dispatch(on: .global()) {
                do {
                    MXLog.info("Fetching event details for \(eventID)")
                    try self._timeline.fetchDetailsForEvent(eventId: eventID)
                } catch {
                    MXLog.error("Failed fetching event details for \(eventID) with error: \(error)")
                }
            }
        }
    }
    
    func invite(userID: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                MXLog.info("Inviting user \(userID)")
                return try .success(self.room.inviteUserById(userId: userID))
            } catch {
                MXLog.error("Failed inviting user \(userID) with error: \(error)")
                return .failure(.failedInvitingUser)
            }
        }
    }
    
    func setName(_ name: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.setName(name: name))
            } catch {
                return .failure(.failedSettingRoomName)
            }
        }
    }

    func setTopic(_ topic: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.setTopic(topic: topic))
            } catch {
                return .failure(.failedSettingRoomTopic)
            }
        }
    }
    
    func removeAvatar() async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self.room.removeAvatar())
            } catch {
                return .failure(.failedRemovingAvatar)
            }
        }
    }
    
    func uploadAvatar(media: MediaInfo) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
                return .failure(.failedUploadingAvatar)
            }

            do {
                let data = try Data(contentsOf: imageURL)
                return try .success(self.room.uploadAvatar(mimeType: mimeType, data: data, mediaInfo: nil))
            } catch {
                return .failure(.failedUploadingAvatar)
            }
        }
    }

    func canUserRedact(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserRedact(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }
    
    func canUserTriggerRoomNotification(userID: String) async -> Result<Bool, RoomProxyError> {
        do {
            return try await .success(room.canUserTriggerRoomNotification(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.failedCheckingPermission)
        }
    }

    // MARK: - Polls

    func createPoll(question: String, answers: [String], pollKind: Poll.Kind) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self._timeline.createPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind)))
            } catch {
                MXLog.error("Failed creating a poll: \(error)")
                return .failure(.failedCreatingPoll)
            }
        }
    }
    
    func editPoll(original eventID: String,
                  question: String,
                  answers: [String],
                  pollKind: Poll.Kind) async -> Result<Void, RoomProxyError> {
        do {
            let originalEvent = try await Task.dispatch(on: .global()) {
                try self._timeline.getEventTimelineItemByEventId(eventId: eventID)
            }
            return try await .success(_timeline.editPoll(question: question, answers: answers, maxSelections: 1, pollKind: .init(pollKind: pollKind), editItem: originalEvent))
        } catch {
            MXLog.error("Failed editing the poll: \(error), eventID: \(eventID)")
            return .failure(.failedEditingPoll)
        }
    }

    func sendPollResponse(pollStartID: String, answers: [String]) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self._timeline.sendPollResponse(pollStartId: pollStartID, answers: answers))
            } catch {
                MXLog.error("Failed sending a poll vote: \(error), pollStartID: \(pollStartID)")
                return .failure(.failedSendingPollResponse)
            }
        }
    }

    func endPoll(pollStartID: String, text: String) async -> Result<Void, RoomProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                return try .success(self._timeline.endPoll(pollStartId: pollStartID, text: text))
            } catch {
                MXLog.error("Failed ending a poll: \(error), pollStartID: \(pollStartID)")
                return .failure(.failedEndingPoll)
            }
        }
    }
    
    // MARK: - Element Call
    
    func elementCallWidgetDriver() -> ElementCallWidgetDriverProtocol {
        ElementCallWidgetDriver(room: room)
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

    /// Force the timeline to load member details so it can populate sender profiles whenever we add a timeline listener
    /// This should become automatic on the RustSDK side at some point
    private func fetchMembers() async {
        await _timeline.fetchMembers()
    }
        
    private func update(displayName: String) {
        self.displayName = displayName
    }

    private func subscribeToBackpagination() {
        let listener = RoomBackpaginationStatusListener { [weak self] status in
            self?.backPaginationStateSubject.send(status)
        }
        do {
            backPaginationStateObservationToken = try _timeline.subscribeToBackPaginationStatus(listener: listener)
        } catch {
            MXLog.error("Failed to subscribe to back pagination state with error: \(error)")
        }
    }
    
    private func subscribeToRoomStateUpdates() {
        roomInfoObservationToken = room.subscribeToRoomInfoUpdates(listener: RoomInfoUpdateListener { [weak self] in
            MXLog.info("Received room info update")
            self?.stateUpdatesSubject.send(())
        })
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

private final class RoomBackpaginationStatusListener: BackPaginationStatusListener {
    private let onUpdateClosure: (BackPaginationStatus) -> Void

    init(_ onUpdateClosure: @escaping (BackPaginationStatus) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }

    func onUpdate(status: BackPaginationStatus) {
        onUpdateClosure(status)
    }
}

private final class RoomInfoUpdateListener: RoomInfoListener {
    private let onUpdateClosure: () -> Void
    
    init(_ onUpdateClosure: @escaping () -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(roomInfo: RoomInfo) {
        onUpdateClosure()
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
