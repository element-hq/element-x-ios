//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc
import Observation

/// A joined MatrixRTC session: membership in, media attached separately.
///
/// Membership and media are separate steps. You are in the call as soon as `join` returned; media
/// is attached with `connectMedia`. Teardown order matters: disconnect media → close the membership
/// subscription → cancel feeds → leave.
@MainActor
@Observable
public final class MatrixRtcSession {
    public let roomID: String
    public let slotID: String
    /// Minted by the core at join time; what every event, roster entry and key report is keyed by.
    public let localMemberID: String
    
    /// Identities from the core's membership projection (who is in the call).
    public private(set) var members: [MatrixRtcMembership] = []
    /// The core's own count, right whenever read; the projection above can lag in some compat modes.
    public private(set) var memberCount = 0
    public private(set) var call: MatrixRtcCall?
    
    private let manager: RtcSessionManagerHandle
    private let transport: MatrixRtcMatrixTransport
    private let feeder: RoomStateFeeder
    private var hasLeft = false
    
    @ObservationIgnored private var membershipSubscription: MembershipSnapshotSubscription?
    @ObservationIgnored private var membershipPoller: Task<Void, Never>?
    
    init(roomID: String,
         slotID: String,
         localMemberID: String,
         manager: RtcSessionManagerHandle,
         transport: MatrixRtcMatrixTransport,
         feeder: RoomStateFeeder) {
        self.roomID = roomID
        self.slotID = slotID
        self.localMemberID = localMemberID
        self.manager = manager
        self.transport = transport
        self.feeder = feeder
    }
    
    func setMemberCount(_ count: Int) {
        memberCount = count
    }
    
    /// Subscribes to membership snapshots, then starts the membership feed — in that order, because
    /// `nextSnapshot()` only reports what changes *after* the subscription exists.
    func start() async {
        do {
            membershipSubscription = try await manager.subscribeMembershipSnapshots(roomId: roomID, slotId: slotID)
        } catch {
            MatrixRtcLog.warning("Cannot subscribe to memberships for \(roomID)/\(slotID): \(error)")
        }
        
        if let membershipSubscription {
            // The Swift binding of `nextSnapshot()` is a non-blocking poll (Android gets a blocking reader):
            // reading after each change would be ideal, a 1 s tick is close enough.
            membershipPoller = Task { [weak self] in
                while !Task.isCancelled {
                    do {
                        if let snapshot = try membershipSubscription.nextSnapshot() {
                            let members = snapshot.map(MatrixRtcMembership.init)
                            self?.updateMembers(members)
                        }
                    } catch {
                        MatrixRtcLog.warning("Membership subscription for \(self?.roomID ?? "?") ended: \(error)")
                        break
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        } else {
            MatrixRtcLog.warning("No membership subscription for \(roomID)/\(slotID), the roster will not update")
        }
        
        feeder.startMemberships()
    }
    
    /// Attaches media. The core knows which membership this session joined as, so no member ID is passed.
    public func connectMedia(transport liveKit: MatrixRtcTransport) async throws -> MatrixRtcCall {
        if let call {
            return call
        }
        guard case .liveKit(let serviceURL) = liveKit else { throw MatrixRtcError.noLiveKitTransport }
        
        let mediaSession: MediaSession
        do {
            mediaSession = try await connectMediaSession(manager: manager,
                                                         config: MediaSessionConfig(roomId: roomID,
                                                                                    slotId: slotID,
                                                                                    userId: transport.userID,
                                                                                    deviceId: transport.deviceID,
                                                                                    livekitServiceUrl: serviceURL.absoluteString),
                                                         tokenProvider: OpenIDTokenProviderAdapter(transport: transport))
        } catch {
            MatrixRtcLog.warning("Failed to connect media for \(roomID)/\(slotID): \(error)")
            throw MatrixRtcError.media("\(error)")
        }
        
        let call = MatrixRtcCall(localMemberID: localMemberID, mediaSession: mediaSession)
        self.call = call
        await call.start()
        MatrixRtcLog.info("Media connected for \(roomID)/\(slotID) as \(localMemberID)")
        return call
    }
    
    /// Idempotent: hanging up and tearing the screen down both leave, and the core rejects a second attempt.
    public func leave(reason: MatrixRtcLeaveReason? = nil) async {
        guard !hasLeft else {
            MatrixRtcLog.debug("Already left \(roomID)/\(slotID)")
            return
        }
        hasLeft = true
        
        await call?.disconnect()
        call = nil
        // Before the leave: a snapshot arriving mid-leave makes the core create a fresh, unseeded session.
        membershipPoller?.cancel()
        membershipSubscription = nil
        feeder.stop()
        
        do {
            let leaveReason = reason.map { FfiLeaveReason(code: $0.code, reason: $0.reason) }
            try await manager.leave(roomId: roomID, slotId: slotID, params: FfiLeaveSessionParams(leaveReason: leaveReason))
            MatrixRtcLog.info("Left \(roomID)/\(slotID)")
        } catch {
            MatrixRtcLog.warning("Failed to leave \(roomID)/\(slotID): \(error)")
        }
    }
    
    private func updateMembers(_ members: [MatrixRtcMembership]) {
        if members.map(\.memberID) != self.members.map(\.memberID) {
            MatrixRtcLog.info("\(members.count) member(s) in \(roomID)/\(slotID): \(members.map(\.memberID))")
        }
        self.members = members
    }
}

private final nonisolated class OpenIDTokenProviderAdapter: OpenIdTokenProvider, Sendable {
    private let transport: MatrixRtcMatrixTransport
    
    init(transport: MatrixRtcMatrixTransport) {
        self.transport = transport
    }
    
    func getOpenIdToken() async throws -> FfiOpenIdToken {
        do {
            let token = try await transport.requestOpenIDToken()
            return FfiOpenIdToken(accessToken: token.accessToken,
                                  tokenType: token.tokenType,
                                  matrixServerName: token.matrixServerName,
                                  expiresInSecs: UInt64(max(0, token.expiresIn)))
        } catch {
            throw MediaFfiError.Token("OpenID token request failed: \(error)")
        }
    }
}
