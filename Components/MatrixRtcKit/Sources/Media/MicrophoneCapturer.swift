//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import MatrixRtc
import Synchronization

/// Pulls the microphone off the engine's real-time thread, converts it to 48 kHz mono Int16 and
/// hands exactly 480-sample frames to the published track.
///
/// Muting stops handing frames over **and** tells the transport (done by the call); the engine and
/// the capture stay up so unmuting is instant.
final nonisolated class MicrophoneCapturer: @unchecked Sendable {
    private let engine: CallAudioEngine
    private let ring = PCMRingBuffer(capacity: AudioFormat.samplesPerFrame * 50)
    private let isMuted = Atomic<Bool>(false)
    private let isTestToneEnabled = Atomic<Bool>(false)
    private let onLevel: @Sendable (MatrixRtcAudioLevel) -> Void
    
    private let state = Mutex<State>(.init())
    
    private struct State {
        var track: FfiLocalTrack?
        var drainer: Task<Void, Never>?
        var converter: AVAudioConverter?
        var inputFormat: AVAudioFormat?
        var frameCount: UInt64 = 0
        var tonePhase: Float = 0
    }
    
    init(engine: CallAudioEngine, onLevel: @escaping @Sendable (MatrixRtcAudioLevel) -> Void) {
        self.engine = engine
        self.onLevel = onLevel
    }
    
    func start(track: FfiLocalTrack) {
        stop()
        state.withLock { $0.track = track }
        
        // Converts to Int16 mono at the hardware rate on the render thread (cheap, no allocation
        // beyond the small scratch buffer), then the drainer resamples to 48 kHz.
        engine.installInputSink { [weak self] _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: audioBufferList))
            guard let first = buffers.first, let data = first.mData else { return noErr }
            
            let inputFormat = engine.inputFormat
            let channels = Int(inputFormat.channelCount)
            let count = Int(frameCount)
            
            // Hardware input is Float32; take channel 0 when it is stereo.
            let floats = data.assumingMemoryBound(to: Float.self)
            let interleaved = inputFormat.isInterleaved
            var scratch = [Int16](repeating: 0, count: count)
            for index in 0..<count {
                let sample = interleaved ? floats[index * channels] : floats[index]
                scratch[index] = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            }
            scratch.withUnsafeBufferPointer { ring.write($0) }
            return noErr
        }
        
        let drainer = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await drain()
        }
        state.withLock { $0.drainer = drainer }
    }
    
    func stop() {
        let drainer = state.withLock { state -> Task<Void, Never>? in
            defer { state.drainer = nil; state.track = nil; state.converter = nil }
            return state.drainer
        }
        drainer?.cancel()
        ring.clear()
    }
    
    func setMuted(_ muted: Bool) {
        isMuted.store(muted, ordering: .relaxed)
    }
    
    /// A fixed 440 Hz sine at a known level takes the capture device out of the picture.
    func setTestToneEnabled(_ enabled: Bool) {
        isTestToneEnabled.store(enabled, ordering: .relaxed)
    }
    
    // MARK: - Private
    
    /// Resamples whatever the hardware produced into 480-sample 48 kHz frames and pushes them.
    private func drain() async {
        var pending = [Int16]()
        let output = [Int16](repeating: 0, count: AudioFormat.samplesPerFrame)
        var frame = Data(count: AudioFormat.bytesPerFrame)
        
        while !Task.isCancelled {
            let available = ring.availableToRead
            if available < 64 {
                try? await Task.sleep(for: .milliseconds(5))
                continue
            }
            
            var chunk = [Int16](repeating: 0, count: available)
            chunk.withUnsafeMutableBufferPointer { ring.read(into: $0) }
            pending += resampleToTarget(chunk)
            
            while pending.count >= AudioFormat.samplesPerFrame {
                var samples = Array(pending.prefix(AudioFormat.samplesPerFrame))
                pending.removeFirst(AudioFormat.samplesPerFrame)
                
                if isTestToneEnabled.load(ordering: .relaxed) {
                    fillTestTone(&samples)
                }
                
                // Meter before the mute check: knowing the microphone is alive while muted is exactly
                // the question a silent call raises.
                let level = samples.withUnsafeBufferPointer { AudioLevelMeter.level(of: $0) }
                let count = state.withLock { state -> UInt64 in
                    state.frameCount += 1
                    return state.frameCount
                }
                if count % 10 == 0 {
                    onLevel(.init(level: level, frameCount: count, underrunCount: nil))
                }
                
                guard !isMuted.load(ordering: .relaxed), let track = state.withLock({ $0.track }) else { continue }
                
                frame.withUnsafeMutableBytes { bytes in
                    bytes.copyBytes(from: samples.withUnsafeBufferPointer { UnsafeRawBufferPointer($0) })
                }
                do {
                    try await track.captureAudio(frame: FfiAudioFrame(data: frame,
                                                                      sampleRate: UInt32(AudioFormat.sampleRate),
                                                                      numChannels: UInt32(AudioFormat.channelCount),
                                                                      samplesPerChannel: UInt32(AudioFormat.samplesPerFrame)))
                } catch {
                    MatrixRtcLog.warning("captureAudio failed: \(error)")
                }
            }
            _ = output
        }
    }
    
    /// Linear resampling from the hardware rate to 48 kHz; the hardware usually *is* 48 kHz, in
    /// which case this is a copy.
    private func resampleToTarget(_ samples: [Int16]) -> [Int16] {
        let inputRate = engine.inputFormat.sampleRate
        guard inputRate > 0, Int(inputRate) != AudioFormat.sampleRate else { return samples }
        let ratio = inputRate / Double(AudioFormat.sampleRate)
        let outputCount = Int(Double(samples.count) / ratio)
        var output = [Int16](repeating: 0, count: outputCount)
        for index in 0..<outputCount {
            let position = Double(index) * ratio
            let lower = Int(position)
            let upper = min(lower + 1, samples.count - 1)
            let fraction = Float(position - Double(lower))
            output[index] = Int16(Float(samples[lower]) * (1 - fraction) + Float(samples[upper]) * fraction)
        }
        return output
    }
    
    private func fillTestTone(_ samples: inout [Int16]) {
        state.withLock { state in
            let step = 2 * Float.pi * 440 / Float(AudioFormat.sampleRate)
            for index in samples.indices {
                samples[index] = Int16(sin(state.tonePhase) * 0.3 * Float(Int16.max))
                state.tonePhase += step
                if state.tonePhase > 2 * .pi {
                    state.tonePhase -= 2 * .pi
                }
            }
        }
    }
}
