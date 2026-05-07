//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation

/// Plays a preview of a notification tone using `AVAudioPlayer`.
/// Players are retained for the duration of playback and released automatically on completion.
class NotificationTonePreviewer: NSObject, AVAudioPlayerDelegate {
    private let lock = NSLock()
    private var playbackRetainer: Set<AVAudioPlayer> = []

    private let userIndicatorController: UserIndicatorControllerProtocol

    init(userIndicatorController: UserIndicatorControllerProtocol) {
        self.userIndicatorController = userIndicatorController
    }

    /// Plays the audio file for the given tone. Shows a toast on failure.
    func preview(_ tone: NotificationAlertTone) {
        do {
            let player = try AVAudioPlayer(contentsOf: tone.location)
            player.delegate = self
            lock.withLock {
                _ = playbackRetainer.insert(player)
            }
            player.play()
        } catch {
            let userIndicator = UserIndicator(type: .toast,
                                              title: UntranslatedL10n.screenNotificationSettingsConfigurationMessageSoundPreviewSoundErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error previewing alert tone \(tone): \(error)")
        }
    }

    /// Releases the player from the retainer set once playback finishes.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        lock.withLock {
            _ = playbackRetainer.remove(player)
        }
    }
}
