//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc

nonisolated extension MatrixRtcStreamKind {
    init(_ kind: FfiStreamKind) {
        switch kind {
        case .microphone: self = .microphone
        case .camera: self = .camera
        case .screenShare: self = .screenShare
        case .screenShareAudio: self = .screenShareAudio
        case .data: self = .data
        }
    }
    
    var ffi: FfiStreamKind {
        switch self {
        case .microphone: .microphone
        case .camera: .camera
        case .screenShare: .screenShare
        case .screenShareAudio: .screenShareAudio
        case .data: .data
        }
    }
}

nonisolated extension MatrixRtcElementCallCompat {
    var ffi: FfiElementCallCompat {
        switch self {
        case .off: .off
        case .stickyEvents: .stickyEvents
        case .stateEvents: .stateEvents
        }
    }
}

nonisolated extension MatrixRtcTransport {
    var ffi: FfiTransportConfig? {
        switch self {
        case .liveKit(let serviceURL): FfiTransportConfig(type: "livekit", livekitServiceUrl: serviceURL.absoluteString)
        case .unsupported: nil
        }
    }
}

nonisolated extension MatrixRtcNotify {
    var ffi: FfiNotifyConfig {
        FfiNotifyConfig(notificationType: kind == .ring ? .ring : .notification,
                        intent: intent.rawValue,
                        lifetimeMs: nil,
                        mentionUserIds: [],
                        mentionRoom: false)
    }
}

nonisolated extension MatrixRtcMembership {
    init(_ membership: JoinedMembership) {
        self.init(memberID: membership.memberId,
                  userID: membership.sender,
                  deviceID: membership.senderDeviceId,
                  application: membership.application)
    }
}

nonisolated extension MatrixRtcParticipant {
    init(_ participant: FfiParticipant) {
        self.init(memberID: participant.memberId,
                  userID: participant.userId,
                  deviceID: participant.deviceId,
                  isLocal: participant.isLocal,
                  isReachable: participant.reachable,
                  streams: participant.streams.map { .init(kind: .init($0.kind), isMuted: $0.muted) },
                  handRaisedAt: participant.handRaisedAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000) })
    }
}

nonisolated extension MatrixRtcReceiveStats {
    init(_ stats: FfiReceiveStats) {
        self.init(packetsReceived: stats.packetsReceived,
                  packetsLost: stats.packetsLost,
                  bytesReceived: stats.bytesReceived,
                  jitter: stats.jitter,
                  framesDecoded: stats.framesDecoded,
                  framesDropped: stats.framesDropped,
                  totalSamplesReceived: stats.totalSamplesReceived,
                  concealedSamples: stats.concealedSamples)
    }
}

nonisolated extension MatrixRtcFrameEncryptionState {
    init(_ state: FfiFrameEncryptionState) {
        switch state {
        case .ok: self = .ok
        case .missingKey: self = .missingKey
        case .decryptionFailed: self = .decryptionFailed
        case .encryptionFailed: self = .encryptionFailed
        case .internalError: self = .internalError
        }
    }
}

nonisolated extension MatrixRtcCallEvent {
    init(_ event: FfiCallEvent) {
        switch event {
        case .participantJoined(let memberId, let userId):
            self = .participantJoined(memberID: memberId, userID: userId)
        case .participantLeft(let memberId):
            self = .participantLeft(memberID: memberId)
        case .streamStarted(let memberId, let kind):
            self = .streamStarted(memberID: memberId, kind: .init(kind))
        case .streamStopped(let memberId, let kind):
            self = .streamStopped(memberID: memberId, kind: .init(kind))
        case .streamMuted(let memberId, let kind):
            self = .streamMuted(memberID: memberId, kind: .init(kind))
        case .streamUnmuted(let memberId, let kind):
            self = .streamUnmuted(memberID: memberId, kind: .init(kind))
        case .activeSpeakers(let speakers):
            self = .activeSpeakers(speakers.map { .init(memberID: $0.memberId, level: $0.level) })
        case .keyImported(let memberId, let keyIndex):
            self = .keyImported(memberID: memberId, keyIndex: keyIndex)
        case .frameEncryptionState(let memberId, let state, _):
            self = .frameEncryptionState(memberID: memberId, state: .init(state))
        case .keyDiscarded(let memberId, let keyIndex, let senderUserId, let senderDeviceId, let reason):
            self = .keyDiscarded(memberID: memberId,
                                 reason: "index \(keyIndex.map(String.init) ?? "?") from \(senderUserId ?? "?")/\(senderDeviceId ?? "?"): \(reason)")
        case .handRaised(let memberId, let raisedAtMs):
            self = .handRaised(memberID: memberId, raisedAt: Date(timeIntervalSince1970: Double(raisedAtMs) / 1000))
        case .handLowered(let memberId):
            self = .handLowered(memberID: memberId)
        case .reaction(let memberId, let emoji, let name, _):
            self = .reaction(memberID: memberId, emoji: emoji, name: name)
        case .unknownParticipant(let identity):
            // Not surfaced: the transport knows an identity the membership projection doesn't (yet).
            self = .mediaConnectionDegraded(false)
            MatrixRtcLog.debug("Unknown participant on the transport: \(identity)")
        case .mediaConnectionState(let degraded):
            self = .mediaConnectionDegraded(degraded)
        case .ended(let reason):
            switch reason {
            case .left: self = .ended(.left)
            case .connectionClosed(let message): self = .ended(.connectionClosed(message: message))
            }
        }
    }
}
