//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import MatrixRustSDK
import Synchronization

// The SDK's listener protocols, each over a closure, so a subscription can say what it delivers where
// it subscribes.

final nonisolated class SDKStateEventsListener: RoomStateEventsListener {
    private let onUpdate: @Sendable ([RoomStateEvent]) -> Void
    
    init(onUpdate: @escaping @Sendable ([RoomStateEvent]) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func onUpdate(events: [RoomStateEvent]) {
        onUpdate(events)
    }
}

final nonisolated class SDKMessageLikeEventsListener: RoomMessageLikeEventsListener {
    private let onEvent: @Sendable (RoomMessageLikeEvent) -> Void
    
    init(onEvent: @escaping @Sendable (RoomMessageLikeEvent) -> Void) {
        self.onEvent = onEvent
    }
    
    func onEvent(event: RoomMessageLikeEvent) {
        onEvent(event)
    }
}

final nonisolated class SDKToDeviceListener: ToDeviceMessageListener {
    private let onMessage: @Sendable (ToDeviceMessage) -> Void
    
    init(onMessage: @escaping @Sendable (ToDeviceMessage) -> Void) {
        self.onMessage = onMessage
    }
    
    func onMessage(message: ToDeviceMessage) {
        onMessage(message)
    }
}

/// Folds the SDK's resets and changes into the whole set, which is what the core wants. The first
/// update is the current set, an empty one included.
final nonisolated class SDKStickyEventsListener: StickyEventsListener {
    private let sink: ElementCallRoomSink
    private let set = Mutex(SDKStickyEventSet())
    
    init(sink: ElementCallRoomSink) {
        self.sink = sink
    }
    
    func onUpdate(update: StickyEventsUpdate) {
        sink.deliverStickyEvents(set.withLock { $0.apply(update) })
    }
}

/// The room's encryption and joined members, both read off the room info, which is what changes when
/// either does. One info subscription for the two, each subject following it in its own task.
final nonisolated class SDKRoomInfoFeed: Sendable {
    let handle: TaskHandle
    
    private let room: Room
    private let logger: (any ElementCallLoggingProtocol)?
    private let encryptionUpdates: AsyncStream<Void>
    private let memberUpdates: AsyncStream<Void>
    
    init(room: Room, logger: (any ElementCallLoggingProtocol)?) {
        self.room = room
        self.logger = logger
        let (encryptionUpdates, encryption) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let (memberUpdates, members) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.encryptionUpdates = encryptionUpdates
        self.memberUpdates = memberUpdates
        handle = room.subscribeToRoomInfoUpdates(listener: SDKRoomInfoListener {
            encryption.yield()
            members.yield()
        })
    }
    
    /// Asked of the homeserver when the store does not know yet, and never answered with a guess: the
    /// core treats cleartext membership as valid in an unencrypted room, so an unknown state delivers
    /// nothing, which keeps the call from joining rather than letting it join an encrypted room
    /// believing it is not.
    func deliverEncryption(into sink: ElementCallRoomSink) async {
        var lastDelivered: Bool?
        func deliver(_ state: EncryptionState) {
            guard let isEncrypted = SDKMappings.isEncrypted(state), isEncrypted != lastDelivered else { return }
            lastDelivered = isEncrypted
            sink.deliverEncryption(isEncrypted: isEncrypted)
        }
        
        do {
            try await deliver(room.latestEncryptionState())
        } catch {
            logger?.log(.warning, "could not fetch the encryption state of \(room.id()): \(error)")
            deliver(room.encryptionState())
        }
        for await _ in encryptionUpdates {
            deliver(room.encryptionState())
        }
    }
    
    /// Re-read on every room info update rather than when the joined count moves: one person leaving
    /// as another joins keeps the count while the membership differs, and the core would carry on
    /// encrypting media for whoever left.
    func deliverJoinedMembers(into sink: ElementCallRoomSink) async {
        var lastDelivered: [String]?
        func deliver() async {
            guard let members = await joinedMembers(), SDKMappings.shouldDeliver(members, lastDelivered: lastDelivered) else { return }
            lastDelivered = members
            sink.deliverJoinedMembers(members)
        }
        
        await deliver()
        for await _ in memberUpdates {
            await deliver()
        }
    }
    
    /// `members()` rather than `membersNoSync()`: it fetches from the homeserver the first time, which
    /// a room we are joined to but have never opened needs, and reads the store after that.
    private func joinedMembers() async -> [String]? {
        do {
            let iterator = try await room.members()
            var joined = [String]()
            while let chunk = iterator.nextChunk(chunkSize: 100) {
                joined.append(contentsOf: chunk.filter { $0.membership == .join }.map(\.userId))
            }
            return joined.sorted()
        } catch {
            logger?.log(.warning, "cannot load the members of \(room.id()): \(error)")
            return nil
        }
    }
}

private final nonisolated class SDKRoomInfoListener: RoomInfoListener {
    private let onUpdate: @Sendable () -> Void
    
    init(onUpdate: @escaping @Sendable () -> Void) {
        self.onUpdate = onUpdate
    }
    
    func call(roomInfo: RoomInfo) {
        onUpdate()
    }
}
