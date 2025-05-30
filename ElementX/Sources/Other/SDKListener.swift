//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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

// MARK: Room

extension SDKListener: RoomInfoListener where T == RoomInfo {
    func call(roomInfo: RoomInfo) { onUpdateClosure(roomInfo) }
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
