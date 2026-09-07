//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc
import Observation
import Synchronization
import UIKit

/// The media half of a session: publishes the microphone, camera and screen, plays every remote
/// member and hands out video frames for tiles. Owned by `MatrixRtcSession`.
@MainActor
@Observable
public final class MatrixRtcCall {
    public let localMemberID: String
    
    /// The transport's roster (not the membership projection; the two can legitimately differ).
    public private(set) var participants: [MatrixRtcParticipant] = []
    public private(set) var audioLevels: [String: MatrixRtcAudioLevel] = [:]
    public private(set) var receiveStats: [String: MatrixRtcReceiveStats] = [:]
    public private(set) var activeSpeakerIDs: Set<String> = []
    public private(set) var frameEncryption: [String: MatrixRtcFrameEncryptionState] = [:]
    public private(set) var isMicrophoneMuted = false
    public private(set) var isAudioTestToneEnabled = false
    public private(set) var isMediaDegraded = false
    public private(set) var hasEnded = false
    
    /// Every core event, after the call itself reacted to it.
    public let events: AsyncStream<MatrixRtcCallEvent>
    private let eventsContinuation: AsyncStream<MatrixRtcCallEvent>.Continuation
    
    private let mediaSession: MediaSession
    private let audioEngine = CallAudioEngine()
    @ObservationIgnored private lazy var microphone = MicrophoneCapturer(engine: audioEngine) { [weak self] level in
        Task { @MainActor in self?.setAudioLevel(level, for: self?.localMemberID) }
    }
    
    private var microphoneTrack: FfiLocalTrack?
    private var playbackSinks = [String: AudioPlaybackSink]()
    private var tasks = [Task<Void, Never>]()
    
    init(localMemberID: String, mediaSession: MediaSession) {
        self.localMemberID = localMemberID
        self.mediaSession = mediaSession
        (events, eventsContinuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(64))
    }
    
    /// Starts the event pump **before** anything announces the call as connected (the stream has no
    /// replay), then sweeps the roster for members already publishing.
    func start() async {
        tasks.append(Task { [weak self] in await self?.pumpEvents() })
        tasks.append(Task { [weak self] in await self?.pollReceiveStats() })
        refreshParticipants()
        for participant in participants where !participant.isLocal && participant.stream(.microphone) != nil {
            playAudio(of: participant.memberID)
        }
    }
    
    // MARK: - Audio device
    
    /// From CallKit's `didActivate audioSession` (or directly on the simulator).
    public func startAudio() {
        do {
            try audioEngine.start()
        } catch {
            MatrixRtcLog.error("Failed starting the audio engine: \(error)")
        }
    }
    
    /// From CallKit's `didDeactivate audioSession`.
    public func stopAudio() {
        audioEngine.stop()
    }
    
    // MARK: - Microphone
    
    public func publishMicrophone() async throws {
        guard microphoneTrack == nil else { return }
        let track: FfiLocalTrack
        do {
            track = try await mediaSession.publish(options: FfiPublishOptions(kind: .microphone,
                                                                              audio: FfiAudioSourceConfig(sampleRate: UInt32(AudioFormat.sampleRate),
                                                                                                          numChannels: UInt32(AudioFormat.channelCount)),
                                                                              video: nil,
                                                                              simulcast: false))
        } catch {
            throw MatrixRtcError.media("Failed to publish the microphone: \(error)")
        }
        microphoneTrack = track
        microphone.setTestToneEnabled(isAudioTestToneEnabled)
        microphone.start(track: track)
        // The transport only learns about a mute once there is a track.
        await setMicrophoneMuted(isMicrophoneMuted)
        MatrixRtcLog.info("Publishing microphone as \(localMemberID)")
    }
    
    /// Stops handing frames over **and** tells the transport, so peers see a deliberate mute rather
    /// than a client that wedged.
    public func setMicrophoneMuted(_ muted: Bool) async {
        isMicrophoneMuted = muted
        microphone.setMuted(muted)
        await setTransportMuted(.microphone, muted: muted)
    }
    
    public func setAudioTestToneEnabled(_ enabled: Bool) {
        isAudioTestToneEnabled = enabled
        microphone.setTestToneEnabled(enabled)
    }
    
    public func disconnect() async {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        audioLevelFlush?.cancel()
        audioLevelFlush = nil
        microphone.stop()
        playbackSinks.values.forEach { $0.stop() }
        playbackSinks.removeAll()
        audioEngine.stop()
        do {
            try await mediaSession.disconnect()
        } catch {
            MatrixRtcLog.warning("Failed to disconnect the media session: \(error)")
        }
        eventsContinuation.finish()
    }
    
    // MARK: - Private
    
    private func pumpEvents() async {
        while !Task.isCancelled, let ffiEvent = await mediaSession.nextEvent() {
            let event = MatrixRtcCallEvent(ffiEvent)
            handle(event)
            eventsContinuation.yield(event)
            refreshParticipants()
        }
        MatrixRtcLog.debug("Media event pump stopped")
    }
    
    private func handle(_ event: MatrixRtcCallEvent) {
        switch event {
        case .streamStarted(let memberID, .microphone) where memberID != localMemberID:
            playAudio(of: memberID)
        case .streamStopped(let memberID, .microphone), .participantLeft(let memberID):
            stopPlayback(of: memberID)
        case .activeSpeakers(let speakers):
            hasTransportSpeakerEvents = true
            activeSpeakerIDs = Set(speakers.map(\.memberID))
        case .frameEncryptionState(let memberID, let state):
            if frameEncryption[memberID] != state {
                MatrixRtcLog.warning("Frame encryption \(state) for \(memberID) (was \(frameEncryption[memberID].map { "\($0)" } ?? "unknown"))")
            }
            frameEncryption[memberID] = state
        case .keyDiscarded(let memberID, let reason):
            MatrixRtcLog.warning("Key for \(memberID) discarded: \(reason)")
        case .keyImported(let memberID, let keyIndex):
            MatrixRtcLog.info("Key index \(keyIndex) imported for \(memberID)")
        case .mediaConnectionDegraded(let degraded):
            isMediaDegraded = degraded
        case .ended(let reason):
            MatrixRtcLog.info("Media session ended: \(reason)")
            hasEnded = true
            playbackSinks.values.forEach { $0.stop() }
            playbackSinks.removeAll()
        default:
            break
        }
    }
    
    /// `streamStarted` and the initial roster sweep both fire for a member already publishing; the
    /// dictionary claim keeps a member from being played twice, slightly out of step.
    private func playAudio(of memberID: String) {
        guard memberID != localMemberID, playbackSinks[memberID] == nil else { return }
        guard let stream = mediaSession.audioStream(memberId: memberID, kind: .microphone) else {
            MatrixRtcLog.warning("Cannot open the audio stream for \(memberID)")
            return
        }
        let sink = AudioPlaybackSink(memberID: memberID, engine: audioEngine) { [weak self] memberID, level in
            Task { @MainActor in self?.setAudioLevel(level, for: memberID) }
        }
        playbackSinks[memberID] = sink
        sink.start(stream: stream)
        MatrixRtcLog.info("Playing audio of \(memberID)")
    }
    
    private func stopPlayback(of memberID: String) {
        playbackSinks.removeValue(forKey: memberID)?.stop()
        audioLevels[memberID] = nil
        pendingAudioLevels[memberID] = nil
    }
    
    private func refreshParticipants() {
        let refreshed = mediaSession.participants().map(MatrixRtcParticipant.init)
        if Set(refreshed.map(\.memberID)) != Set(participants.map(\.memberID)) {
            MatrixRtcLog.info("Media roster \(refreshed.count): \(refreshed.map { "\($0.memberID)\($0.isLocal ? " (self)" : "")" })")
        }
        participants = refreshed
    }
    
    /// Above this RMS a member counts as speaking when the transport sends no speaker events.
    private static let speakingThreshold: Float = 0.02
    private var hasTransportSpeakerEvents = false
    
    /// Meters report ten times a second *per member*; published one by one, an eleven-person call
    /// would rebuild every tile over a hundred times a second. Levels are collected here and
    /// published in one batch per sample period, which is all a meter needs.
    private static let audioLevelSamplePeriod: Duration = .milliseconds(100)
    @ObservationIgnored private var pendingAudioLevels: [String: MatrixRtcAudioLevel] = [:]
    @ObservationIgnored private var audioLevelFlush: Task<Void, Never>?
    
    private func setAudioLevel(_ level: MatrixRtcAudioLevel, for memberID: String?) {
        guard let memberID else { return }
        pendingAudioLevels[memberID] = level
        guard audioLevelFlush == nil else { return }
        audioLevelFlush = Task { [weak self] in
            try? await Task.sleep(for: Self.audioLevelSamplePeriod)
            guard !Task.isCancelled else { return }
            self?.flushAudioLevels()
        }
    }
    
    private func flushAudioLevels() {
        audioLevelFlush = nil
        guard !pendingAudioLevels.isEmpty else { return }
        var levels = audioLevels
        for (memberID, level) in pendingAudioLevels {
            levels[memberID] = level
        }
        pendingAudioLevels.removeAll(keepingCapacity: true)
        audioLevels = levels
        
        // LiveKit's active-speaker updates have not been observed through the core (its event is
        // logged at trace level only, so the log cannot say whether they fire); derive them from the
        // decoded audio until they show up.
        guard !hasTransportSpeakerEvents else { return }
        let speaking = Set(audioLevels.filter { $0.value.level > Self.speakingThreshold }.keys)
        if speaking != activeSpeakerIDs {
            activeSpeakerIDs = speaking
            let ranked = speaking.sorted { (audioLevels[$0]?.level ?? 0) > (audioLevels[$1]?.level ?? 0) }
            eventsContinuation.yield(.activeSpeakers(ranked.map { .init(memberID: $0, level: audioLevels[$0]?.level ?? 0) }))
        }
    }
    
    /// RTCP reports arrive about once a second; polling faster only repeats values.
    private func pollReceiveStats() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            var stats = [String: MatrixRtcReceiveStats]()
            for participant in participants where !participant.isLocal {
                if let audio = await mediaSession.receiveStats(memberId: participant.memberID, kind: .microphone) {
                    stats[participant.memberID] = .init(audio)
                }
            }
            receiveStats = stats
        }
    }
    
    private func setTransportMuted(_ kind: MatrixRtcStreamKind, muted: Bool) async {
        do {
            try await mediaSession.setLocalMuted(kind: kind.ffi, muted: muted)
        } catch {
            MatrixRtcLog.warning("Could not tell the transport \(kind) is \(muted ? "muted" : "unmuted"): \(error)")
        }
    }
}
