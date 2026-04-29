//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation

class NotificationTonePreviewer: NSObject, AVAudioPlayerDelegate {
    private let lock = NSLock()
    private var playbackRetainer: Set<AVAudioPlayer> = []

    private let userIndicatorController: UserIndicatorControllerProtocol

    init(userIndicatorController: UserIndicatorControllerProtocol) {
        self.userIndicatorController = userIndicatorController
    }

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
                                              title: UntranslatedL10n.screenNotificationSettingsConfigurationAlertTonePreviewToneErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error previewing alert tone \(tone): \(error)")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        lock.withLock {
            _ = playbackRetainer.remove(player)
        }
    }
}
