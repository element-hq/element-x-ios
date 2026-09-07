//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import MatrixRtc
import Synchronization

/// Plays one remote member: a source node on the engine pulls from a ring that a filler task keeps
/// topped up from the decoded stream. Under-runs play silence and are counted; a full ring drops
/// the oldest audio so latency stays bounded.
final nonisolated class AudioPlaybackSink: @unchecked Sendable {
    let memberID: String
    private let engine: CallAudioEngine
    private let ring = PCMRingBuffer(capacity: AudioFormat.samplesPerFrame * 20)
    private let prefill = AudioFormat.samplesPerFrame * 3
    private let flags = RenderFlags()
    private let frameCount = Atomic<UInt64>(0)
    
    /// Shared with the render block, which must not capture the sink itself.
    private final class RenderFlags: @unchecked Sendable {
        let isPrimed = Atomic<Bool>(false)
        let isDetached = Atomic<Bool>(false)
        let underruns = Atomic<Int>(0)
    }
    
    private let filler = Mutex<Task<Void, Never>?>(nil)
    private let onLevel: @Sendable (String, MatrixRtcAudioLevel) -> Void
    
    init(memberID: String, engine: CallAudioEngine, onLevel: @escaping @Sendable (String, MatrixRtcAudioLevel) -> Void) {
        self.memberID = memberID
        self.engine = engine
        self.onLevel = onLevel
    }
    
    func start(stream: AudioFrameStream) {
        let ring = ring
        let flags = flags
        let prefill = prefill
        
        // The render block captures only atomics and the ring, never self, so detaching while the
        // engine runs is safe.
        engine.addSourceNode(for: memberID) { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let first = buffers.first, let data = first.mData else { return noErr }
            let floats = data.assumingMemoryBound(to: Float.self)
            let count = Int(frameCount)
            
            if flags.isDetached.load(ordering: .relaxed) || (!flags.isPrimed.load(ordering: .relaxed) && ring.availableToRead < prefill) {
                for index in 0..<count {
                    floats[index] = 0
                }
                return noErr
            }
            flags.isPrimed.store(true, ordering: .relaxed)
            
            var scratch = [Int16](repeating: 0, count: count)
            let real = scratch.withUnsafeMutableBufferPointer { ring.read(into: $0) }
            if real < count {
                flags.underruns.wrappingAdd(1, ordering: .relaxed)
                if real == 0 {
                    flags.isPrimed.store(false, ordering: .relaxed)
                }
            }
            for index in 0..<count {
                floats[index] = Float(scratch[index]) / Float(Int16.max)
            }
            return noErr
        }
        
        let task = Task.detached(priority: .userInitiated) { [weak self] in
            while !Task.isCancelled, let frame = await stream.next() {
                self?.push(frame)
            }
            MatrixRtcLog.debug("Audio stream ended for \(self?.memberID ?? "?")")
        }
        filler.withLock { $0 = task }
    }
    
    func stop() {
        filler.withLock { $0?.cancel(); $0 = nil }
        flags.isDetached.store(true, ordering: .relaxed)
        engine.removeSourceNode(for: memberID)
    }
    
    private func push(_ frame: FfiAudioFrame) {
        frame.data.withUnsafeBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            if ring.availableToWrite < samples.count {
                ring.dropOldest(samples.count - ring.availableToWrite)
            }
            ring.write(samples)
            let count = frameCount.wrappingAdd(1, ordering: .relaxed).newValue
            if count % 10 == 0 {
                onLevel(memberID, .init(level: AudioLevelMeter.level(of: samples),
                                        frameCount: count,
                                        underrunCount: flags.underruns.load(ordering: .relaxed)))
            }
        }
    }
}
