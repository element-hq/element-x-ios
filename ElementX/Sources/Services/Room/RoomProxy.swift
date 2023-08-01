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
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let backgroundTaskName = "SendRoomEvent"
    
    private let userInitiatedDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.userinitiated", qos: .userInitiated)
    private let lowPriorityDispatchQueue = DispatchQueue(label: "io.element.elementx.roomproxy.lowpriority", qos: .utility)
    
    private var sendMessageBackgroundTask: BackgroundTaskProtocol?
    
    private(set) var displayName: String?
    
    private var roomTimelineObservationToken: TaskHandle?
    private var backPaginationStateObservationToken: TaskHandle?

    private let backPaginationStateSubject = PassthroughSubject<BackPaginationStatus, Never>()
    private let membersSubject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
    var membersPublisher: AnyPublisher<[RoomMemberProxyProtocol], Never> {
        membersSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var timelineListener: RoomTimelineListener?
    private let updatesSubject = PassthroughSubject<TimelineDiff, Never>()
    var updatesPublisher: AnyPublisher<TimelineDiff, Never> {
        updatesSubject.eraseToAnyPublisher()
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
        
        let settings = RoomSubscription(requiredState: [RequiredState(key: "m.room.name", value: ""),
                                                        RequiredState(key: "m.room.topic", value: ""),
                                                        RequiredState(key: "m.room.avatar", value: ""),
                                                        RequiredState(key: "m.room.canonical_alias", value: ""),
                                                        RequiredState(key: "m.room.join_rules", value: "")],
                                        timelineLimit: UInt32(SlidingSyncConstants.defaultTimelineLimit))
        roomListItem.subscribe(settings: settings)

        let timelineListener = RoomTimelineListener { [weak self] timelineDiff in
            self?.updatesSubject.send(timelineDiff)
        }

        self.timelineListener = timelineListener
        
        let result = room.addTimelineListener(listener: timelineListener)
        roomTimelineObservationToken = result.itemsStream

        subscribeToBackpagination()
        
        innerTimelineProvider = await RoomTimelineProvider(currentItems: result.items,
                                                           updatePublisher: updatesPublisher,
                                                           backPaginationStatePublisher: backPaginationStateSubject.eraseToAnyPublisher())
        
        Task {
            await fetchMembers()
            await updateMembers()
        }
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

    var encryptionBadgeImage: UIImage? {
        guard isEncrypted else {
            return nil
        }

        //  return trusted image for now, should be updated after verification status known
        return Asset.Images.encryptionTrusted.image
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
        
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomProxyError> {
        do {
            try await Task.dispatch(on: .global()) {
                try self.room.paginateBackwards(opts: .untilNumItems(eventLimit: UInt16(requestSize), items: UInt16(untilNumberOfItems), waitForToken: true))
            }
            
            return .success(())
        } catch {
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendReadReceipt(for eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.sendReadReceipt(eventId: eventID)
                return .success(())
            } catch {
                return .failure(.failedSendingReadReceipt)
            }
        }
    }
        
    func messageEventContent(for eventID: String) -> RoomMessageEventContent? {
        try? room.getTimelineEventContentByEventId(eventId: eventID)
    }
    
    func sendMessageEventContent(_ messageContent: RoomMessageEventContent) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let transactionId = genTransactionId()
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            self.room.send(msg: messageContent, txnId: transactionId)
            return .success(())
        }
    }
    
    func sendMessage(_ message: String, inReplyTo eventID: String? = nil) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let transactionId = genTransactionId()
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                if let eventID {
                    try self.room.sendReply(msg: message, inReplyToEventId: eventID, txnId: transactionId)
                } else {
                    let messageContent = messageEventContentFromMarkdown(md: message)
                    self.room.send(msg: messageContent, txnId: transactionId)
                }
            } catch {
                return .failure(.failedSendingMessage)
            }
            return .success(())
        }
    }
    
    func toggleReaction(_ reaction: String, to eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.toggleReaction(eventId: eventID, key: reaction)
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
                   requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = room.sendImage(url: url.path(), thumbnailUrl: thumbnailURL.path(), imageInfo: imageInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        requestHandle(handle)
        
        do {
            try handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendVideo(url: URL,
                   thumbnailURL: URL,
                   videoInfo: VideoInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = room.sendVideo(url: url.path(), thumbnailUrl: thumbnailURL.path(), videoInfo: videoInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        requestHandle(handle)
        
        do {
            try handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendAudio(url: URL,
                   audioInfo: AudioInfo,
                   progressSubject: CurrentValueSubject<Double, Never>?,
                   requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = room.sendAudio(url: url.path(), audioInfo: audioInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        requestHandle(handle)
        
        do {
            try handle.join()
        } catch {
            return .failure(.failedSendingMedia)
        }
        
        return .success(())
    }
    
    func sendFile(url: URL,
                  fileInfo: FileInfo,
                  progressSubject: CurrentValueSubject<Double, Never>?,
                  requestHandle: (SendAttachmentJoinHandleProtocol) -> Void) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }
        
        let handle = room.sendFile(url: url.path(), fileInfo: fileInfo, progressWatcher: UploadProgressListener { progress in
            progressSubject?.send(progress)
        })
        
        requestHandle(handle)
        
        do {
            try handle.join()
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

        let transactionId = genTransactionId()

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            .success(self.room.sendLocation(body: body,
                                            geoUri: geoURI.string,
                                            description: description,
                                            zoomLevel: zoomLevel,
                                            assetType: assetType,
                                            txnId: transactionId))
        }
    }

    func retrySend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            self.room.retrySend(txnId: transactionID)
        }
    }

    func cancelSend(transactionID: String) async {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            self.room.cancelSend(txnId: transactionID)
        }
    }

    func editMessage(_ newMessage: String, original eventID: String) async -> Result<Void, RoomProxyError> {
        sendMessageBackgroundTask = await backgroundTaskService.startBackgroundTask(withName: backgroundTaskName, isReusable: true)
        defer {
            sendMessageBackgroundTask?.stop()
        }

        let transactionId = genTransactionId()

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.edit(newMsg: newMessage, originalEventId: eventID, txnId: transactionId)
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
        
        let transactionID = genTransactionId()
        
        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                try self.room.redact(eventId: eventID, reason: nil, txnId: transactionID)
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
            let roomMembersProxies = try await Task.dispatch(on: .global()) {
                try self.room.members().map {
                    RoomMemberProxy(member: $0, backgroundTaskService: self.backgroundTaskService)
                }
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

        return await Task.dispatch(on: userInitiatedDispatchQueue) {
            do {
                let member = try self.room.member(userId: userID)
                return .success(RoomMemberProxy(member: member, backgroundTaskService: self.backgroundTaskService))
            } catch {
                return .failure(.failedRetrievingMember)
            }
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
            self?.room.retryDecryption(sessionIds: [sessionID])
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
                    try self.room.fetchDetailsForEvent(eventId: eventID)
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
    
    func setName(_ name: String?) async -> Result<Void, RoomProxyError> {
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
                return try .success(self.room.uploadAvatar(mimeType: mimeType, data: [UInt8](data)))
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

    // MARK: - Private
    
    /// Force the timeline to load member details so it can populate sender profiles whenever we add a timeline listener
    /// This should become automatic on the RustSDK side at some point
    private func fetchMembers() async {
        await Task.dispatch(on: .global()) {
            do {
                _ = try self.room.fetchMembers()
            } catch {
                MXLog.error("Failed fetching members: \(error)")
            }
        }
    }
        
    private func update(displayName: String) {
        self.displayName = displayName
    }

    private func subscribeToBackpagination() {
        let listener = RoomBackpaginationStatusListener { [weak self] status in
            self?.backPaginationStateSubject.send(status)
        }
        do {
            backPaginationStateObservationToken = try room.subscribeToBackPaginationStatus(listener: listener)
        } catch {
            MXLog.error("Failed to subscribe to back pagination state with error: \(error)")
        }
    }
}

private final class RoomTimelineListener: TimelineListener {
    private let onUpdateClosure: (TimelineDiff) -> Void
   
    init(_ onUpdateClosure: @escaping (TimelineDiff) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(diff: TimelineDiff) {
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
