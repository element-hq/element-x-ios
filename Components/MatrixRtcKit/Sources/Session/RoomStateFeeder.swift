//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc
import Synchronization

/// Feeds one room's state to the core: joined members, encryption, then memberships.
///
/// Ordering is not cosmetic. Members and encryption go in **before** the join (a sender the core
/// cannot place in the room is rejected as `SenderNotInRoom`); memberships only **after** the join,
/// because the compat mode fixed by the join decides how they are parsed.
final nonisolated class RoomStateFeeder: Sendable {
    private let manager: RtcSessionManagerHandle
    private let transport: MatrixRtcMatrixTransport
    private let roomID: String
    private let slotID: String
    private let compat: MatrixRtcElementCallCompat
    private let onMemberCount: @Sendable (Int) -> Void
    
    private let tasks: Mutex<[Task<Void, Never>]> = .init([])
    private let roomMembersFed: Mutex<CheckedContinuation<Void, Never>?> = .init(nil)
    private let haveRoomMembers = Mutex(false)
    
    init(manager: RtcSessionManagerHandle,
         transport: MatrixRtcMatrixTransport,
         roomID: String,
         slotID: String,
         compat: MatrixRtcElementCallCompat,
         onMemberCount: @escaping @Sendable (Int) -> Void) {
        self.manager = manager
        self.transport = transport
        self.roomID = roomID
        self.slotID = slotID
        self.compat = compat
        self.onMemberCount = onMemberCount
    }
    
    /// Members and encryption. Call before joining; `awaitRoomMembers()` gates the join itself.
    func start() {
        // `onRoomSlotsReceived` is deliberately not fed: no Element Call generation publishes
        // `m.rtc.slot`, and a truthful "no open slots" would project out every member, us included.
        let members = Task { [self] in
            for await userIDs in transport.joinedMemberIDs(roomID: roomID) {
                // A room we are joined to always contains us: empty means "not loaded yet", and
                // feeding it says the room is deserted, excluding every membership.
                guard !userIDs.isEmpty else { continue }
                MatrixRtcLog.info("Feeding \(userIDs.count) joined member(s) for \(roomID)")
                await feed("room members") { try await manager.onRoomMembersReceived(roomId: roomID, joinedUserIds: userIDs) }
                markRoomMembersFed()
            }
        }
        let encryption = Task { [self] in
            let isEncrypted = await transport.isRoomEncrypted(roomID: roomID)
            MatrixRtcLog.info("Feeding encryption=\(isEncrypted) for \(roomID)")
            await feed("room encryption") { try await manager.onRoomEncryptionReceived(roomId: roomID, encrypted: isEncrypted) }
        }
        tasks.withLock { $0 += [members, encryption] }
    }
    
    /// Suspends until the first non-empty member list reached the core.
    func awaitRoomMembers() async {
        let alreadyFed = haveRoomMembers.withLock { $0 }
        if alreadyFed {
            return
        }
        await withCheckedContinuation { continuation in
            let fedMeanwhile = haveRoomMembers.withLock { fed -> Bool in
                if fed {
                    return true
                }
                roomMembersFed.withLock { $0 = continuation }
                return false
            }
            if fedMeanwhile {
                continuation.resume()
            }
        }
    }
    
    /// Memberships. Call after the join and after `subscribeMembershipSnapshots`.
    func startMemberships() {
        let task: Task<Void, Never> = switch compat {
        case .stateEvents:
            Task { [self] in await feedStateMemberships() }
        case .off, .stickyEvents:
            // Sticky-event memberships need a sticky-event feed the released SDK bindings do not expose yet.
            Task { MatrixRtcLog.warning("Membership feed for compat mode \(compat) is not implemented on iOS") }
        }
        tasks.withLock { $0.append(task) }
    }
    
    func stop() {
        tasks.withLock { tasks in
            tasks.forEach { $0.cancel() }
            tasks.removeAll()
        }
    }
    
    // MARK: - Private
    
    private func markRoomMembersFed() {
        let continuation = haveRoomMembers.withLock { fed -> CheckedContinuation<Void, Never>? in
            fed = true
            return roomMembersFed.withLock { continuation in
                defer { continuation = nil }
                return continuation
            }
        }
        continuation?.resume()
    }
    
    /// Room state is replaced, never removed: a departure is a present event with `{}` content, so
    /// an empty list can only mean the bucket has not synced. Feeding it states the call is deserted,
    /// ourselves included, and ~20 s later the dead man's switch empties our membership mid-call.
    private func feedStateMemberships() async {
        var lastFed: [LegacyStateMemberEvent]?
        for await events in transport.roomStateEvents(roomID: roomID, eventType: MatrixRtcEventTypes.legacyStateMember) {
            let memberships = events
                .filter { $0.eventType == MatrixRtcEventTypes.legacyStateMember || $0.eventType == "m.call.member" }
                .map(Self.legacyStateMemberEvent)
                .sorted { $0.stateKey < $1.stateKey }
            
            guard !memberships.isEmpty else {
                MatrixRtcLog.info("Not feeding an empty state membership snapshot for \(roomID), it would read as a deserted call")
                continue
            }
            // The SDK re-reads whole room state far more often than a membership changes.
            guard memberships != lastFed else { continue }
            lastFed = memberships
            
            let departures = memberships.filter { $0.contentJson.trimmingCharacters(in: .whitespacesAndNewlines) == "{}" }.count
            MatrixRtcLog.info("Feeding \(memberships.count) state membership(s) for \(roomID) (departures=\(departures)): \(memberships.map { "\($0.sender)@\($0.stateKey)" })")
            await feed("state memberships") {
                try await manager.setCurrentMembership(roomId: roomID, memberEvents: [], legacyStateEvents: memberships)
            }
            await updateMemberCount()
        }
    }
    
    /// A missing timestamp becomes 0 ("long expired"), which is better than dropping the event and far
    /// better than the wall clock, which would resurrect an expired membership as a phantom member.
    private static func legacyStateMemberEvent(_ event: MatrixRtcRoomStateEvent) -> LegacyStateMemberEvent {
        let timestamp = event.originServerTimestamp.map { UInt64($0.timeIntervalSince1970 * 1000) } ?? 0
        return LegacyStateMemberEvent(eventId: event.eventID,
                                      sender: event.sender,
                                      stateKey: event.stateKey,
                                      originServerTs: timestamp,
                                      contentJson: event.contentJSON)
    }
    
    /// The count is a query, right whenever it is read; the snapshot subscription is not woken in
    /// every compat mode, so this is the number the UI should trust.
    private func updateMemberCount() async {
        do {
            let count = try await manager.memberCount(roomId: roomID, slotId: slotID)
            MatrixRtcLog.info("Core reports \(count.map(String.init) ?? "no") member(s) for \(roomID)/\(slotID)")
            if let count {
                onMemberCount(Int(count))
            }
        } catch {
            MatrixRtcLog.warning("Cannot read the member count for \(roomID)/\(slotID): \(error)")
        }
    }
    
    /// Feeding is best effort: the next snapshot supersedes what this one failed to deliver, and an
    /// error escaping a background task would take the process (and the log) with it.
    private func feed(_ what: String, _ body: () async throws -> Void) async {
        do {
            try await body()
        } catch {
            MatrixRtcLog.error("Core rejected \(what) for \(roomID): \(error)")
        }
    }
}
