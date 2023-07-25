//
// Copyright 2022 New Vector Ltd
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

import SwiftUI

struct RoomNotificationSettingsScreen: View {
    @ObservedObject var context: RoomNotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            allowCustomSettingSection

            if !context.allowCustomSetting {
                defaultSettingSection
            } else {
                customSettingsSection
            }
        }
        .compoundForm()
        .navigationTitle(L10n.screenRoomDetailsNotificationTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .roomNotifications)
    }
    
    // MARK: - Private

    @ViewBuilder
    private var allowCustomSettingSection: some View {
        Section {
            Toggle(isOn: $context.allowCustomSetting) {
                Text(L10n.screenRoomNotificationSettingsAllowCustom)
            }
            .toggleStyle(.compoundForm)
            .accessibilityIdentifier(A11yIdentifiers.roomNotificationSettingsScreen.allowCustomSetting)
            .disabled(context.viewState.notificationSettingsState.isLoading)
            .onChange(of: context.allowCustomSetting) { _ in
                context.send(viewAction: .changedAllowCustomSettings)
            }
        } footer: {
            Text(L10n.screenRoomNotificationSettingsAllowCustomFootnote)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var defaultSettingSection: some View {
        Section {
            if context.viewState.isRestoringDefautSetting {
                Text(L10n.commonLoading)
                    .foregroundColor(.compound.textPlaceholder)
            } else {
                Text(context.viewState.strings.string(for: context.viewState.notificationSettingsState))
                    .foregroundColor(.compound.textPrimary)
            }
        } header: {
            Text(L10n.screenRoomNotificationSettingsDefaultSettingTitle)
                .compoundFormSectionHeader()
        } footer: {
            Text(context.viewState.strings.customSettingFootnote)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var customSettingsSection: some View {
        Section {
            Picker("", selection: $context.customMode) {
                ForEach(context.viewState.availableCustomRoomNotificationModes, id: \.self) { mode in
                    Text(context.viewState.strings.string(for: mode))
                        .tag(mode)
                }
            }
            .onChange(of: context.customMode) { mode in
                context.send(viewAction: .setCustomMode(mode))
            }
            .labelsHidden()
            .pickerStyle(.inline)
        } header: {
            Text(L10n.screenRoomNotificationSettingsCustomSettingsTitle)
                .compoundFormSectionHeader()
        }
        .compoundFormSection()
    }
}

// MARK: - Previews

struct RoomNotificationSettingsScreen_Previews: PreviewProvider {
    static let viewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        let model = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                            roomProxy: roomProxy)
        
        return model
    }()

    static let viewModelCustom = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        let model = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                            roomProxy: roomProxy)
        
        return model
    }()

    static var previews: some View {
        RoomNotificationSettingsScreen(context: viewModel.context)
            .previewDisplayName("Default")
        RoomNotificationSettingsScreen(context: viewModelCustom.context)
            .previewDisplayName("Custom")
    }
}
