//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
