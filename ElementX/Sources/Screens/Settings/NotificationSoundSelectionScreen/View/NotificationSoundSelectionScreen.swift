//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct NotificationSoundSelectionScreen: View {
    @ObservedObject var context: NotificationSoundSelectionScreenViewModel.Context
    
    var body: some View {
        Form {
            ForEach(NotificationSound.soundsByCategory(), id: \.category) { group in
                Section {
                    ForEach(group.sounds) { sound in
                        ListRow(label: .plain(title: sound.displayName),
                                kind: .button {
                                    context.send(viewAction: .selectSound(sound))
                                })
                                .accessibilityAddTraits(sound == context.selectedSound ? .isSelected : [])
                                .listRowBackground(
                                    sound == context.selectedSound ?
                                        Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault
                                )
                                .overlay(alignment: .trailing) {
                                    if sound == context.selectedSound {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.compound.iconAccentTertiary)
                                            .padding(.trailing, 16)
                                    }
                                }
                    }
                } header: {
                    if let category = group.category {
                        Text(category == .alertTones ? L10n.screenNotificationSettingsSoundAlertTones : L10n.screenNotificationSettingsSoundClassic)
                            .compoundListSectionHeader()
                    }
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenNotificationSettingsSoundTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct NotificationSoundSelectionScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel: NotificationSoundSelectionScreenViewModel = {
        let appSettings = AppSettings()
        return NotificationSoundSelectionScreenViewModel(appSettings: appSettings)
    }()

    static var previews: some View {
        NavigationStack {
            NotificationSoundSelectionScreen(context: viewModel.context)
        }
    }
}
