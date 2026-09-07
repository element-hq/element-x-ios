//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation

/// Configures the shared audio session for a call. Never activates it when CallKit is in charge —
/// CallKit activates the session and reports it through `didActivate`, and activating it ourselves
/// makes that callback fire twice or not at all.
public nonisolated enum CallAudioSessionConfigurator {
    /// No `.defaultToSpeaker` here on purpose: with it, clearing the output override still lands on
    /// the speaker and the earpiece becomes unreachable. Video calls ask for the speaker explicitly
    /// once the session is active (`setLoudspeaker`).
    public static func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP])
        try session.setPreferredSampleRate(Double(AudioFormat.sampleRate))
        try session.setPreferredIOBufferDuration(0.01)
    }
    
    /// For the simulator and any path where CallKit is not driving activation.
    public static func activate() throws {
        try AVAudioSession.sharedInstance().setActive(true, options: [])
    }
    
    public static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    /// Speaker vs. whatever the system would pick (earpiece, headset, Bluetooth).
    public static func setLoudspeaker(_ enabled: Bool) throws {
        try AVAudioSession.sharedInstance().overrideOutputAudioPort(enabled ? .speaker : .none)
    }
    
    public static var isLoudspeaker: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .builtInSpeaker }
    }
    
    public static var isBuiltInReceiver: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .builtInReceiver }
    }
    
    public static var currentOutputName: String? {
        AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName
    }
}
