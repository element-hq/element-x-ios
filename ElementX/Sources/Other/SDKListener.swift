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
final class SDKListener<T> {
    private let onUpdateClosure: (T) -> Void
    
    /// Creates a new listener.
    /// - Parameter onUpdateClosure: A closure that will be called whenever a new value is available.
    init(_ onUpdateClosure: @escaping (T) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
}

// MARK: QRCodeLoginService

extension SDKListener: QrLoginProgressListener where T == QrLoginProgress {
    func onUpdate(state: QrLoginProgress) { onUpdateClosure(state) }
}

extension SDKListener: GrantQrLoginProgressListener where T == GrantQrLoginProgress {
    func onUpdate(state: GrantQrLoginProgress) { onUpdateClosure(state) }
}

extension SDKListener: GrantGeneratedQrLoginProgressListener where T == GrantGeneratedQrLoginProgress {
    func onUpdate(state: GrantGeneratedQrLoginProgress) { onUpdateClosure(state) }
}

// MARK: ClientProxy

extension SDKListener: MediaPreviewConfigListener where T == MediaPreviewConfig? {
    func onChange(mediaPreviewConfig: MediaPreviewConfig?) { onUpdateClosure(mediaPreviewConfig) }
}

extension SDKListener: SyncServiceStateObserver where T == SyncServiceState {
    func onUpdate(state: SyncServiceState) { onUpdateClosure(state) }
}

extension SDKListener: RoomListServiceStateListener where T == RoomListServiceState {
    func onUpdate(state: RoomListServiceState) { onUpdateClosure(state) }
}

extension SDKListener: RoomListServiceSyncIndicatorListener where T == RoomListServiceSyncIndicator {
    func onUpdate(syncIndicator: RoomListServiceSyncIndicator) { onUpdateClosure(syncIndicator) }
}

extension SDKListener: VerificationStateListener where T == VerificationState {
    func onUpdate(status: VerificationState) { onUpdateClosure(status) }
}

extension SDKListener: IgnoredUsersListener where T == [String] {
    func call(ignoredUserIds: [String]) { onUpdateClosure(ignoredUserIds) }
}

extension SDKListener: SendQueueRoomErrorListener where T == (String, ClientError) {
    func onError(roomId: String, error: ClientError) { onUpdateClosure((roomId, error)) }
}

// MARK: SecureBackupController

extension SDKListener: BackupStateListener where T == BackupState {
    func onUpdate(status: BackupState) { onUpdateClosure(status) }
}

extension SDKListener: RecoveryStateListener where T == RecoveryState {
    func onUpdate(status: RecoveryState) { onUpdateClosure(status) }
}

extension SDKListener: EnableRecoveryProgressListener where T == EnableRecoveryProgress {
    func onUpdate(status: EnableRecoveryProgress) { onUpdateClosure(status) }
}

extension SDKListener: BackupSteadyStateListener where T == BackupUploadState {
    func onUpdate(status: BackupUploadState) { onUpdateClosure(status) }
}

// MARK: RoomSummaryProvider

extension SDKListener: RoomListEntriesListener where T == [RoomListEntriesUpdate] {
    func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) { onUpdateClosure(roomEntriesUpdate) }
}

extension SDKListener: RoomListLoadingStateListener where T == RoomListLoadingState {
    func onUpdate(state: RoomListLoadingState) { onUpdateClosure(state) }
}

// MARK: Spaces

extension SDKListener: SpaceServiceJoinedSpacesListener where T == [SpaceListUpdate] {
    func onUpdate(rooms: [SpaceListUpdate]) { onUpdateClosure(rooms) }
}

extension SDKListener: SpaceRoomListEntriesListener where T == [SpaceListUpdate] {
    func onUpdate(roomUpdates: [SpaceListUpdate]) { onUpdateClosure(roomUpdates) }
}

extension SDKListener: SpaceRoomListPaginationStateListener where T == SpaceRoomListPaginationState {
    func onUpdate(paginationState: SpaceRoomListPaginationState) { onUpdateClosure(paginationState) }
}

extension SDKListener: SpaceRoomListSpaceListener where T == SpaceRoom? {
    func onUpdate(space: SpaceRoom?) { onUpdateClosure(space) }
}

// MARK: Room

extension SDKListener: RoomInfoListener where T == RoomInfo {
    func call(roomInfo: RoomInfo) { onUpdateClosure(roomInfo) }
}

extension SDKListener: CallDeclineListener where T == String {
    func call(declinerUserId: String) { onUpdateClosure(declinerUserId) }
}

extension SDKListener: TypingNotificationsListener where T == [String] {
    func call(typingUserIds: [String]) { onUpdateClosure(typingUserIds) }
}

extension SDKListener: IdentityStatusChangeListener where T == [IdentityStatusChange] {
    func call(identityStatusChange: [IdentityStatusChange]) { onUpdateClosure(identityStatusChange) }
}

extension SDKListener: KnockRequestsListener where T == [KnockRequest] {
    func call(joinRequests: [KnockRequest]) { onUpdateClosure(joinRequests) }
}

// MARK: TimelineProxy

extension SDKListener: PaginationStatusListener where T == RoomPaginationStatus {
    func onUpdate(status: RoomPaginationStatus) { onUpdateClosure(status) }
}

extension SDKListener: ProgressWatcher where T == Double {
    func transmissionProgress(progress: TransmissionProgress) {
        DispatchQueue.main.async { [weak self] in
            self?.onUpdateClosure(Double(progress.current) / Double(progress.total))
        }
    }
}

// MARK: TimelineItemProvider

extension SDKListener: TimelineListener where T == [TimelineDiff] {
    func onUpdate(diff: [TimelineDiff]) { onUpdateClosure(diff) }
}

// MARK: RoomDirectorySearchProxy

extension SDKListener: RoomDirectorySearchEntriesListener where T == [RoomDirectorySearchEntryUpdate] {
    func onUpdate(roomEntriesUpdate: [RoomDirectorySearchEntryUpdate]) { onUpdateClosure(roomEntriesUpdate) }
}
