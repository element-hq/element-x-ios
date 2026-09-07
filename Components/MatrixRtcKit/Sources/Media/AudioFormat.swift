//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation

/// 48 kHz mono 10 ms frames: what the RTC stack works in internally, so nothing has to resample,
/// and the usual WebRTC tick.
nonisolated enum AudioFormat {
    static let sampleRate = 48000
    static let channelCount = 1
    static let samplesPerFrame = 480
    static let bytesPerFrame = samplesPerFrame * MemoryLayout<Int16>.size
    
    /// The interleaved Int16 format frames cross the FFI in.
    static let pcm16 = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                     sampleRate: Double(sampleRate),
                                     channels: AVAudioChannelCount(channelCount),
                                     interleaved: true)!
    
    /// The Float32 format the engine's mixer prefers for source nodes.
    static let float32 = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: Double(sampleRate),
                                       channels: AVAudioChannelCount(channelCount),
                                       interleaved: false)!
}

/// RMS level of a PCM16 buffer, 0...1.
nonisolated enum AudioLevelMeter {
    static func level(of samples: UnsafeBufferPointer<Int16>) -> Float {
        guard !samples.isEmpty else { return 0 }
        var sum: Float = 0
        for sample in samples {
            let value = Float(sample) / Float(Int16.max)
            sum += value * value
        }
        return min(1, (sum / Float(samples.count)).squareRoot())
    }
}
