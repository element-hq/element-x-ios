//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AudioToolbox
import AVFoundation
import Combine
import SwiftUI

typealias NotificationSoundSelectionScreenViewModelType = StateStoreViewModel<NotificationSoundSelectionScreenViewState, NotificationSoundSelectionScreenViewAction>

class NotificationSoundSelectionScreenViewModel: NotificationSoundSelectionScreenViewModelType, NotificationSoundSelectionScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSoundSelectionScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    private var audioPlayer: AVAudioPlayer?
    
    var actions: AnyPublisher<NotificationSoundSelectionScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        
        let currentSound = NotificationSound.availableSounds.first { sound in
            sound.fileName == appSettings.notificationSoundName
        } ?? NotificationSound.defaultSound
        
        let bindings = NotificationSoundSelectionScreenViewStateBindings(selectedSound: currentSound)
        super.init(initialViewState: NotificationSoundSelectionScreenViewState(bindings: bindings,
                                                                               sounds: NotificationSound.availableSounds))
    }
    
    // MARK: - Public
    
    override func process(viewAction: NotificationSoundSelectionScreenViewAction) {
        switch viewAction {
        case .selectSound(let sound):
            state.bindings.selectedSound = sound
            appSettings.notificationSoundName = sound.fileName
            playSound(sound)
            actionsSubject.send(.complete)
        }
    }
    
    // MARK: - Private
    
    private func playSound(_ sound: NotificationSound) {
        guard let fileName = sound.fileName else {
            // Play system default sound
            AudioServicesPlaySystemSound(1007) // SMS received tone
            return
        }
        
        // Get the sound file URL
        let resourceName = (fileName as NSString).deletingPathExtension
        let pathExtension = (fileName as NSString).pathExtension
        guard let soundURL = Bundle.main.url(forResource: resourceName,
                                             withExtension: pathExtension) else {
            MXLog.error("Failed to find sound file: \(fileName)")
            return
        }
        
        do {
            // Configure audio session to play even when ringer is off
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and play audio
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            MXLog.info("Playing sound: \(fileName)")
        } catch {
            MXLog.error("Failed to play sound: \(fileName), error: \(error)")
        }
    }
}
