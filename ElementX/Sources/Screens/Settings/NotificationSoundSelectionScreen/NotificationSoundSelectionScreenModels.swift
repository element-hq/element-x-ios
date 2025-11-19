//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum NotificationSoundSelectionScreenViewModelAction {
    case complete
}

struct NotificationSoundSelectionScreenViewState: BindableState {
    var bindings: NotificationSoundSelectionScreenViewStateBindings
    let sounds: [NotificationSound]
}

struct NotificationSoundSelectionScreenViewStateBindings {
    var selectedSound: NotificationSound
}

enum NotificationSoundSelectionScreenViewAction {
    case selectSound(NotificationSound)
}

enum SoundCategory: String {
    case alertTones
    case classic
}

struct NotificationSound: Identifiable, Equatable {
    let id: String
    let fileName: String?
    let displayName: String
    let category: SoundCategory?
    
    static let defaultSound = NotificationSound(id: "default",
                                                fileName: nil,
                                                displayName: L10n.screenNotificationSettingsSoundDefault,
                                                category: nil)
    
    static let availableSounds: [NotificationSound] = {
        let alertTones = [
            NotificationSound(id: "note", fileName: "note.m4r", displayName: "Note", category: .alertTones),
            NotificationSound(id: "apex", fileName: "Apex.m4r", displayName: "Apex", category: .alertTones),
            NotificationSound(id: "aurora", fileName: "aurora.m4r", displayName: "Aurora", category: .alertTones),
            NotificationSound(id: "bamboo", fileName: "bamboo.m4r", displayName: "Bamboo", category: .alertTones),
            NotificationSound(id: "beacon", fileName: "Beacon.m4r", displayName: "Beacon", category: .alertTones),
            NotificationSound(id: "chord", fileName: "chord.m4r", displayName: "Chord", category: .alertTones),
            NotificationSound(id: "circles", fileName: "circles.m4r", displayName: "Circles", category: .alertTones),
            NotificationSound(id: "hello", fileName: "hello.m4r", displayName: "Hello", category: .alertTones),
            NotificationSound(id: "input", fileName: "input.m4r", displayName: "Input", category: .alertTones),
            NotificationSound(id: "keys", fileName: "keys.m4r", displayName: "Keys", category: .alertTones),
            NotificationSound(id: "opening", fileName: "Opening.m4r", displayName: "Opening", category: .alertTones),
            NotificationSound(id: "popcorn", fileName: "popcorn.m4r", displayName: "Popcorn", category: .alertTones),
            NotificationSound(id: "pulse", fileName: "pulse.m4r", displayName: "Pulse", category: .alertTones),
            NotificationSound(id: "synth", fileName: "synth.m4r", displayName: "Synth", category: .alertTones)
        ]
        
        let classicSounds = [
            NotificationSound(id: "bell", fileName: "Bell.caf", displayName: "Bell", category: .classic),
            NotificationSound(id: "boing", fileName: "Boing.caf", displayName: "Boing", category: .classic),
            NotificationSound(id: "glass", fileName: "Glass.caf", displayName: "Glass", category: .classic),
            NotificationSound(id: "harp", fileName: "Harp.caf", displayName: "Harp", category: .classic),
            NotificationSound(id: "message", fileName: "message.caf", displayName: "Message", category: .classic),
            NotificationSound(id: "timepassing", fileName: "TimePassing.caf", displayName: "Time Passing", category: .classic),
            NotificationSound(id: "tritone", fileName: "Tri-tone.caf", displayName: "Tri-tone", category: .classic),
            NotificationSound(id: "xylophone", fileName: "Xylophone.caf", displayName: "Xylophone", category: .classic)
        ]
        
        return [defaultSound] + alertTones + classicSounds
    }()
    
    static func soundsByCategory() -> [(category: SoundCategory?, sounds: [NotificationSound])] {
        let grouped = Dictionary(grouping: availableSounds) { $0.category }
        return [
            (category: nil, sounds: grouped[nil] ?? []),
            (category: .alertTones, sounds: grouped[.alertTones] ?? []),
            (category: .classic, sounds: grouped[.classic] ?? [])
        ]
    }
}
