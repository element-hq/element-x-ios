//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation

protocol AudioSessionProtocol: AnyObject {
    func requestRecordPermission(_ response: @escaping (Bool) -> Void)
    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AudioSessionProtocol {
    func setActive(_ active: Bool) throws {
        try setActive(active, options: [])
    }
}

// sourcery: AutoMockable
extension AudioSessionProtocol { }

extension AVAudioSession: AudioSessionProtocol { }
