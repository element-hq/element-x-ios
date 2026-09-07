//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Synchronization

/// One `AVAudioEngine` for both directions: the platform's echo cancellation only works when the
/// microphone and the speaker live in the same IO unit.
///
/// Under CallKit the engine must only start once the provider activated the audio session
/// (`didActivate`), never before — starting early yields silence or `-10868`.
final nonisolated class CallAudioEngine: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var isVoiceProcessingConfigured = false
    private var sinkNode: AVAudioSinkNode?
    private var sourceNodes = [String: AVAudioSourceNode]()
    private var isRunning = false
    private var configurationObserver: NSObjectProtocol?
    
    var onConfigurationChange: (@Sendable () -> Void)?
    
    init() {
        // Posted synchronously on whichever thread reconfigured the graph — which may be a thread
        // currently holding `lock` (attaching a node) — so the restart must hop off it first.
        configurationObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                                                       object: engine,
                                                                       queue: nil) { [weak self] _ in
            MatrixRtcLog.info("Audio engine configuration changed, restarting")
            DispatchQueue.global(qos: .userInitiated).async { self?.restartAfterConfigurationChange() }
        }
    }
    
    deinit {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
        }
    }
    
    /// The hardware input format, only meaningful while the session is active.
    var inputFormat: AVAudioFormat {
        engine.inputNode.outputFormat(forBus: 0)
    }
    
    /// Installs the microphone sink. `receiver` runs on the real-time thread: copy and return.
    func installInputSink(_ receiver: @escaping AVAudioSinkNodeReceiverBlock) {
        lock.withLock {
            if let sinkNode {
                engine.detach(sinkNode)
            }
            let node = AVAudioSinkNode(receiverBlock: receiver)
            engine.attach(node)
            // The sink takes the input node's own format; converting happens off the render thread.
            engine.connect(engine.inputNode, to: node, format: nil)
            sinkNode = node
        }
    }
    
    func addSourceNode(for memberID: String, render: @escaping AVAudioSourceNodeRenderBlock) {
        lock.withLock {
            if let existing = sourceNodes[memberID] {
                engine.detach(existing)
            }
            let node = AVAudioSourceNode(format: AudioFormat.float32, renderBlock: render)
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: AudioFormat.float32)
            sourceNodes[memberID] = node
        }
    }
    
    func removeSourceNode(for memberID: String) {
        lock.withLock {
            guard let node = sourceNodes.removeValue(forKey: memberID) else { return }
            engine.disconnectNodeInput(node)
            engine.detach(node)
        }
    }
    
    /// Call from CallKit's `didActivate` (or directly on the simulator, where CallKit never activates).
    func start() throws {
        try lock.withLock {
            guard !isRunning else { return }
            // Voice processing (AEC/AGC/NS) must be enabled before prepare(), and only once the
            // session is active or the input format reads as 0 Hz.
            if !isVoiceProcessingConfigured {
                do {
                    try engine.inputNode.setVoiceProcessingEnabled(true)
                } catch {
                    // The simulator has no voice processing; a call without AEC still works.
                    MatrixRtcLog.warning("Voice processing unavailable: \(error)")
                }
                isVoiceProcessingConfigured = true
            }
            // Keep the output path alive even with no remote member yet, so the mixer format is fixed.
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)
            engine.prepare()
            try engine.start()
            isRunning = true
            MatrixRtcLog.info("Audio engine started, input \(engine.inputNode.outputFormat(forBus: 0))")
        }
    }
    
    /// Call from CallKit's `didDeactivate`; the session itself is CallKit's to deactivate.
    func stop() {
        lock.withLock {
            guard isRunning else { return }
            engine.stop()
            isRunning = false
            MatrixRtcLog.info("Audio engine stopped")
        }
    }
    
    private func restartAfterConfigurationChange() {
        let wasRunning = lock.withLock { isRunning }
        guard wasRunning else { return }
        lock.withLock { isRunning = false }
        onConfigurationChange?()
        do {
            try start()
        } catch {
            MatrixRtcLog.error("Failed restarting the audio engine after a configuration change: \(error)")
        }
    }
}
