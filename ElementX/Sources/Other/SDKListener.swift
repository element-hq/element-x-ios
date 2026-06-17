//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// A helper class that can be passed as this listener for SDK callbacks.
///
/// To use this you'll need to add a conformance to the required listener
/// protocol with a specialisation for the type it listens for.
final nonisolated class SDKListener<T>: Sendable {
    private let onUpdateClosure: @Sendable (T) -> Void
    
    /// Creates a new listener.
    /// - Parameter onUpdateClosure: A closure that will be called whenever a new value is available.
    init(_ onUpdateClosure: @escaping @Sendable (T) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
}

nonisolated extension SDKListener where T: Sendable {
    /// Creates a new listener that delivers its updates on the main actor in FIFO order,
    /// guaranteeing one in-flight update at a time.
    ///
    /// The SDK calls listeners from arbitrary threads, use this whenever the updates
    /// need to touch main actor state. The internal stream (and so the long-lived task
    /// consuming it) ends when the listener is released.
    /// - Parameter onUpdate: A closure that will be called on the main actor whenever a new value is available.
    static func onMainActor(_ onUpdate: @escaping @MainActor (T) -> Void) -> SDKListener<T> {
        let (stream, continuation) = AsyncStream<T>.makeStream()
        
        Task { @MainActor in
            for await value in stream {
                onUpdate(value)
            }
        }
        
        // The wrapper is owned by the listener's closure, so when the SDK releases the listener
        // (its subscription handle being dropped) the wrapper deinits and finishes the stream,
        // ending the consumer task above. Deiniting the continuation alone does *not* terminate
        // the stream (see SE-0406), which would otherwise leak the task.
        let continuationWrapper = StreamContinuationWrapper(continuation)
        return SDKListener { value in
            continuationWrapper.continuation.yield(value)
        }
    }
}

/// Owns an `AsyncStream.Continuation` and finishes its stream when released.
private final nonisolated class StreamContinuationWrapper<Element: Sendable>: Sendable {
    let continuation: AsyncStream<Element>.Continuation
    
    init(_ continuation: AsyncStream<Element>.Continuation) {
        self.continuation = continuation
    }
    
    deinit {
        continuation.finish()
    }
}

// MARK: QRCodeLoginService

nonisolated extension SDKListener: QrLoginProgressListener where T == QrLoginProgress {
    func onUpdate(state: QrLoginProgress) {
        onUpdateClosure(state)
    }
}

nonisolated extension SDKListener: GrantQrLoginProgressListener where T == GrantQrLoginProgress {
    func onUpdate(state: GrantQrLoginProgress) {
        onUpdateClosure(state)
    }
}

nonisolated extension SDKListener: GrantGeneratedQrLoginProgressListener where T == GrantGeneratedQrLoginProgress {
    func onUpdate(state: GrantGeneratedQrLoginProgress) {
        onUpdateClosure(state)
    }
}

// MARK: ClientProxy

nonisolated extension SDKListener: MediaPreviewConfigListener where T == MediaPreviewConfig? {
    func onChange(mediaPreviewConfig: MediaPreviewConfig?) {
        onUpdateClosure(mediaPreviewConfig)
    }
}

nonisolated extension SDKListener: SyncServiceStateObserver where T == SyncServiceState {
    func onUpdate(state: SyncServiceState) {
        onUpdateClosure(state)
    }
}

nonisolated extension SDKListener: RoomListServiceStateListener where T == RoomListServiceState {
    func onUpdate(state: RoomListServiceState) {
        onUpdateClosure(state)
    }
}

nonisolated extension SDKListener: RoomListServiceSyncIndicatorListener where T == RoomListServiceSyncIndicator {
    func onUpdate(syncIndicator: RoomListServiceSyncIndicator) {
        onUpdateClosure(syncIndicator)
    }
}

nonisolated extension SDKListener: VerificationStateListener where T == VerificationState {
    func onUpdate(status: VerificationState) {
        onUpdateClosure(status)
    }
}

nonisolated extension SDKListener: IgnoredUsersListener where T == [String] {
    func call(ignoredUserIds: [String]) {
        onUpdateClosure(ignoredUserIds)
    }
}

nonisolated extension SDKListener: SendQueueRoomErrorListener where T == (String, ClientError) {
    func onError(roomId: String, error: ClientError) {
        onUpdateClosure((roomId, error))
    }
}

nonisolated extension SDKListener: SendQueueRoomUpdateListener where T == (String, RoomSendQueueUpdate) {
    func onUpdate(roomId: String, update: RoomSendQueueUpdate) {
        onUpdateClosure((roomId, update))
    }
}

// MARK: SecureBackupController

nonisolated extension SDKListener: BackupStateListener where T == BackupState {
    func onUpdate(status: BackupState) {
        onUpdateClosure(status)
    }
}

nonisolated extension SDKListener: RecoveryStateListener where T == RecoveryState {
    func onUpdate(status: RecoveryState) {
        onUpdateClosure(status)
    }
}

nonisolated extension SDKListener: EnableRecoveryProgressListener where T == EnableRecoveryProgress {
    func onUpdate(status: EnableRecoveryProgress) {
        onUpdateClosure(status)
    }
}

nonisolated extension SDKListener: BackupSteadyStateListener where T == BackupUploadState {
    func onUpdate(status: BackupUploadState) {
        onUpdateClosure(status)
    }
}

// MARK: RoomSummaryProvider

nonisolated extension SDKListener: RoomListEntriesListener where T == [RoomListEntriesUpdate] {
    func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
        onUpdateClosure(roomEntriesUpdate)
    }
}

nonisolated extension SDKListener: RoomListLoadingStateListener where T == RoomListLoadingState {
    func onUpdate(state: RoomListLoadingState) {
        onUpdateClosure(state)
    }
}

// MARK: Spaces

nonisolated extension SDKListener: SpaceServiceJoinedSpacesListener where T == [SpaceListUpdate] {
    func onUpdate(rooms: [SpaceListUpdate]) {
        onUpdateClosure(rooms)
    }
}

nonisolated extension SDKListener: SpaceRoomListEntriesListener where T == [SpaceListUpdate] {
    func onUpdate(roomUpdates: [SpaceListUpdate]) {
        onUpdateClosure(roomUpdates)
    }
}

nonisolated extension SDKListener: SpaceRoomListPaginationStateListener where T == SpaceRoomListPaginationState {
    func onUpdate(paginationState: SpaceRoomListPaginationState) {
        onUpdateClosure(paginationState)
    }
}

nonisolated extension SDKListener: SpaceRoomListSpaceListener where T == SpaceRoom? {
    func onUpdate(space: SpaceRoom?) {
        onUpdateClosure(space)
    }
}

nonisolated extension SDKListener: SpaceServiceSpaceFiltersListener where T == [SpaceFilterUpdate] {
    func onUpdate(filterUpdates: [SpaceFilterUpdate]) {
        onUpdateClosure(filterUpdates)
    }
}

// MARK: Room

nonisolated extension SDKListener: RoomInfoListener where T == RoomInfo {
    func call(roomInfo: RoomInfo) {
        onUpdateClosure(roomInfo)
    }
}

nonisolated extension SDKListener: CallDeclineListener where T == String {
    func call(declinerUserId: String) {
        onUpdateClosure(declinerUserId)
    }
}

nonisolated extension SDKListener: TypingNotificationsListener where T == [String] {
    func call(typingUserIds: [String]) {
        onUpdateClosure(typingUserIds)
    }
}

nonisolated extension SDKListener: IdentityStatusChangeListener where T == [IdentityStatusChange] {
    func call(identityStatusChange: [IdentityStatusChange]) {
        onUpdateClosure(identityStatusChange)
    }
}

nonisolated extension SDKListener: KnockRequestsListener where T == [KnockRequest] {
    func call(joinRequests: [KnockRequest]) {
        onUpdateClosure(joinRequests)
    }
}

nonisolated extension SDKListener: LiveLocationsListener where T == [LiveLocationShareUpdate] {
    func onUpdate(updates: [LiveLocationShareUpdate]) {
        onUpdateClosure(updates)
    }
}

nonisolated extension SDKListener: BeaconInfoListener where T == BeaconInfoUpdate {
    func onUpdate(update: BeaconInfoUpdate) {
        onUpdateClosure(update)
    }
}

nonisolated extension SDKListener: ThreadListEntriesListener where T == [ThreadListUpdate] {
    func onUpdate(diff: [ThreadListUpdate]) {
        onUpdateClosure(diff)
    }
}

nonisolated extension SDKListener: ThreadListPaginationStateListener where T == ThreadListPaginationState {
    func onUpdate(state: ThreadListPaginationState) {
        onUpdateClosure(state)
    }
}

// MARK: TimelineProxy

nonisolated extension SDKListener: PaginationStatusListener where T == PaginationStatus {
    func onUpdate(status: PaginationStatus) {
        onUpdateClosure(status)
    }
}

nonisolated extension SDKListener: ProgressWatcher where T == Double {
    func transmissionProgress(progress: TransmissionProgress) {
        DispatchQueue.main.async { [weak self] in
            self?.onUpdateClosure(Double(progress.current) / Double(progress.total))
        }
    }
}

// MARK: TimelineItemProvider

nonisolated extension SDKListener: TimelineListener where T == [TimelineDiff] {
    func onUpdate(diff: [TimelineDiff]) {
        onUpdateClosure(diff)
    }
}

// MARK: RoomDirectorySearchProxy

nonisolated extension SDKListener: RoomDirectorySearchEntriesListener where T == [RoomDirectorySearchEntryUpdate] {
    func onUpdate(roomEntriesUpdate: [RoomDirectorySearchEntryUpdate]) {
        onUpdateClosure(roomEntriesUpdate)
    }
}
