//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public nonisolated enum MatrixRtcConstants {
    /// The application every room call uses.
    public static let callApplication = "m.call"
    /// The slot Element Call opens for a room-wide call. MSC4143 requires the `{application}#` prefix.
    public static let roomCallSlotID = "m.call#ROOM"
}

public nonisolated enum MatrixRtcEventTypes {
    /// MSC4143 membership, spec and unstable spellings.
    public static let member = ["m.rtc.member", "org.matrix.msc4143.rtc.member"]
    /// The pre-MSC4354 Element Call membership room state.
    public static let legacyStateMember = "org.matrix.msc3401.call.member"
    /// MSC4143 media key to-device type.
    public static let encryptionKey = "org.matrix.msc4143.rtc.encryption_key"
    /// Element Call's own media key dialect (a `keys` array), sent *instead of* the spec type.
    public static let legacyEncryptionKey = "io.element.call.encryption_keys"
}

public nonisolated enum MatrixRtcStreamKind: Sendable, Hashable {
    case microphone, camera, screenShare, screenShareAudio, data
}

/// How the membership is published, fixed for the lifetime of a session.
public nonisolated enum MatrixRtcElementCallCompat: String, Sendable, CaseIterable, Codable {
    /// MSC4143 as it stands.
    case off
    /// Membership as an MSC4354 sticky event with legacy fields alongside.
    case stickyEvents
    /// `org.matrix.msc3401.call.member` room state and delayed state events; what Element Web speaks today.
    case stateEvents
}

public nonisolated enum MatrixRtcTransport: Sendable, Hashable {
    case liveKit(serviceURL: URL)
    case unsupported(type: String)
}

public nonisolated enum MatrixRtcCallIntent: String, Sendable {
    case audio, video
}

/// MSC4075 notification sent with the membership when *starting* a call.
public nonisolated struct MatrixRtcNotify: Sendable, Hashable {
    public enum Kind: Sendable { case ring, notification }
    
    public let kind: Kind
    public let intent: MatrixRtcCallIntent
    
    public init(kind: Kind, intent: MatrixRtcCallIntent) {
        self.kind = kind
        self.intent = intent
    }
}

public nonisolated struct MatrixRtcLeaveReason: Sendable, Hashable {
    public let code: String
    public let reason: String?
    
    public init(code: String, reason: String? = nil) {
        self.code = code
        self.reason = reason
    }
}

public nonisolated struct MatrixRtcMembership: Sendable, Hashable, Identifiable {
    public let memberID: String
    public let userID: String
    public let deviceID: String?
    public let application: String?
    
    public var id: String {
        memberID
    }
}

public nonisolated struct MatrixRtcStreamState: Sendable, Hashable {
    public let kind: MatrixRtcStreamKind
    public let isMuted: Bool
    
    public init(kind: MatrixRtcStreamKind, isMuted: Bool) {
        self.kind = kind
        self.isMuted = isMuted
    }
}

/// The transport's view of a member; differs legitimately from the membership projection.
public nonisolated struct MatrixRtcParticipant: Sendable, Hashable, Identifiable {
    public let memberID: String
    public let userID: String
    public let deviceID: String?
    public let isLocal: Bool
    public let isReachable: Bool
    public let streams: [MatrixRtcStreamState]
    public let handRaisedAt: Date?
    
    public init(memberID: String, userID: String, deviceID: String?, isLocal: Bool, isReachable: Bool, streams: [MatrixRtcStreamState], handRaisedAt: Date?) {
        self.memberID = memberID
        self.userID = userID
        self.deviceID = deviceID
        self.isLocal = isLocal
        self.isReachable = isReachable
        self.streams = streams
        self.handRaisedAt = handRaisedAt
    }
    
    public var id: String {
        memberID
    }
    
    public func stream(_ kind: MatrixRtcStreamKind) -> MatrixRtcStreamState? {
        streams.first { $0.kind == kind }
    }
    
    public func isPublishing(_ kind: MatrixRtcStreamKind) -> Bool {
        stream(kind).map { !$0.isMuted } ?? false
    }
}

public nonisolated struct MatrixRtcSpeakingMember: Sendable, Hashable {
    public let memberID: String
    public let level: Float
}

public nonisolated enum MatrixRtcFrameEncryptionState: Sendable, Hashable {
    case ok, missingKey, decryptionFailed, encryptionFailed, internalError
}

public nonisolated enum MatrixRtcEndReason: Sendable, Hashable {
    case left
    case connectionClosed(message: String)
}

public nonisolated enum MatrixRtcCallEvent: Sendable, Hashable {
    case participantJoined(memberID: String, userID: String)
    case participantLeft(memberID: String)
    case streamStarted(memberID: String, kind: MatrixRtcStreamKind)
    case streamStopped(memberID: String, kind: MatrixRtcStreamKind)
    case streamMuted(memberID: String, kind: MatrixRtcStreamKind)
    case streamUnmuted(memberID: String, kind: MatrixRtcStreamKind)
    case activeSpeakers([MatrixRtcSpeakingMember])
    case keyImported(memberID: String, keyIndex: UInt8)
    case keyDiscarded(memberID: String, reason: String)
    case frameEncryptionState(memberID: String, state: MatrixRtcFrameEncryptionState)
    case handRaised(memberID: String, raisedAt: Date)
    case handLowered(memberID: String)
    case reaction(memberID: String, emoji: String, name: String)
    case mediaConnectionDegraded(Bool)
    case ended(MatrixRtcEndReason)
}

/// Cumulative receive counters for one stream; sample twice and diff.
public nonisolated struct MatrixRtcReceiveStats: Sendable, Hashable {
    public let packetsReceived: UInt64
    public let packetsLost: Int64
    public let bytesReceived: UInt64
    public let jitter: Double
    public let framesDecoded: UInt64
    public let framesDropped: UInt64
    public let totalSamplesReceived: UInt64
    public let concealedSamples: UInt64
    
    /// Concealment rising in step with samples received means the silence being played is fabricated.
    public var concealedFraction: Float? {
        totalSamplesReceived > 0 ? Float(concealedSamples) / Float(totalSamplesReceived) : nil
    }
}

public nonisolated struct MatrixRtcAudioLevel: Sendable, Hashable {
    /// RMS of the decoded (or captured) PCM, 0...1.
    public let level: Float
    public let frameCount: UInt64
    /// Playback under-runs reported by the audio device, when known.
    public let underrunCount: Int?
}

/// What is arriving (or being captured) on a video stream: upright size and measured frame rate.
public nonisolated struct MatrixRtcVideoInfo: Sendable, Hashable {
    public let width: Int
    public let height: Int
    public let framesPerSecond: Int
    
    public var aspect: CGFloat {
        CGFloat(width) / CGFloat(max(1, height))
    }
    
    public init(width: Int, height: Int, framesPerSecond: Int) {
        self.width = width
        self.height = height
        self.framesPerSecond = framesPerSecond
    }
}

/// What a tile actually draws, so the SFU sends only the layer that fits.
public nonisolated struct MatrixRtcVideoConstraints: Sendable, Hashable {
    public let isVisible: Bool
    /// The drawn size in pixels, nil to let the SFU pick.
    public let pixelSize: CGSize?
    
    public init(isVisible: Bool, pixelSize: CGSize?) {
        self.isVisible = isVisible
        self.pixelSize = pixelSize
    }
}

public nonisolated struct MatrixRtcOpenIDToken: Sendable {
    public let accessToken: String
    public let tokenType: String
    public let matrixServerName: String
    public let expiresIn: TimeInterval
    
    public init(accessToken: String, tokenType: String, matrixServerName: String, expiresIn: TimeInterval) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.matrixServerName = matrixServerName
        self.expiresIn = expiresIn
    }
}

public nonisolated enum MatrixRtcError: Error, Sendable {
    case notStarted
    case alreadyJoined(roomID: String)
    case notJoined
    case noLiveKitTransport
    case malformedSlotID(String)
    case ffi(String)
    case media(String)
    /// The host could not set up its Matrix side for the room.
    case transport(String)
}
