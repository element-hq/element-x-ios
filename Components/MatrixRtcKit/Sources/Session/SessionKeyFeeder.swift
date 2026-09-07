//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc
import Synchronization

/// Feeds media keys to the core for the whole Matrix session.
///
/// To-device delivery cannot be caught up on: the SDK hands each message to whoever is subscribed
/// at that moment and forgets it. Subscribing per call would drop the key the far end rotates the
/// instant it sees us join, leaving a member at `MISSING_KEY` for the entire call.
final nonisolated class SessionKeyFeeder: Sendable {
    private let manager: RtcSessionManagerHandle
    private let transport: MatrixRtcMatrixTransport
    private let tasks: Mutex<[Task<Void, Never>]> = .init([])
    
    init(manager: RtcSessionManagerHandle, transport: MatrixRtcMatrixTransport) {
        self.manager = manager
        self.transport = transport
    }
    
    func start() {
        let specKeys = Task { [manager, transport] in
            for await message in transport.toDeviceMessages(eventTypes: [MatrixRtcEventTypes.encryptionKey]) {
                guard let key = EncryptionKeyMapper.map(message) else {
                    MatrixRtcLog.warning("Ignoring an unusable encryption key from \(message.attestedSenderID)")
                    continue
                }
                // `crossSigned` is what makes the core silently drop a key, so log what we claimed.
                MatrixRtcLog.info("Encryption key for \(key.memberId) index \(key.keyIndex) from \(key.senderUserId ?? "?")/\(key.senderDeviceId ?? "?") crossSigned=\(key.senderIsCrossSigned)")
                await Self.feed("encryption key for \(key.memberId)") { try await manager.receiveEncryptionKey(key: key) }
            }
        }
        
        // Element Call sends its keys under its own type *instead of* the spec one, with a `keys`
        // array the core parses itself. Subscribed unconditionally: the compat mode is chosen at join
        // time, far too late for a message that is delivered exactly once.
        let legacyKeys = Task { [manager, transport] in
            for await message in transport.toDeviceMessages(eventTypes: [MatrixRtcEventTypes.legacyEncryptionKey]) {
                guard message.wasEncrypted else {
                    MatrixRtcLog.warning("Dropping a cleartext Element Call encryption key")
                    continue
                }
                MatrixRtcLog.info("Element Call encryption key from \(message.attestedSenderID)/\(message.senderDeviceID ?? "?") crossSigned=\(message.isSenderCrossSigned)")
                await Self.feed("Element Call key from \(message.attestedSenderID)") {
                    try await manager.receiveLegacyEncryptionKey(sender: message.attestedSenderID,
                                                                 contentJson: message.contentJSON,
                                                                 wasEncrypted: true,
                                                                 senderDeviceId: message.senderDeviceID,
                                                                 senderIsCrossSigned: message.isSenderCrossSigned)
                }
            }
        }
        
        tasks.withLock { $0 += [specKeys, legacyKeys] }
    }
    
    func stop() {
        tasks.withLock { tasks in
            tasks.forEach { $0.cancel() }
            tasks.removeAll()
        }
    }
    
    /// Losing one key is recoverable (the sender rotates again on the next membership change), losing
    /// the process is not — so nothing thrown by the core escapes here.
    private static func feed(_ what: String, _ body: () async throws -> Void) async {
        do {
            try await body()
        } catch {
            MatrixRtcLog.error("Core rejected the \(what): \(error)")
        }
    }
}
