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
            headerSection

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
    private var headerSection: some View {
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
            Text(L10n.screenRoomNotificationSettingsDefaultSettingTitle.uppercased())
                .foregroundColor(.compound.textSecondary)
        } footer: {
            Text(context.viewState.strings.customSettingFootnote)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var customSettingsSection: some View {
        Section {
            ForEach(context.viewState.availableCustomRoomNotificationModes, id: \.self) { mode in
                Button {
                    context.send(viewAction: .setCustomMode(mode))
                } label: {
                    Text(context.viewState.strings.string(for: mode))
                }
                .disabled(context.viewState.isApplyingCustomMode)
                .buttonStyle(customModeButtonStyle(mode: mode))
            }
        } header: {
            Text(L10n.screenRoomNotificationSettingsCustomSettingsTitle.uppercased())
                .foregroundColor(.compound.textSecondary)
        }
        .compoundFormSection()
    }
    
    private func customModeButtonStyle(mode: RoomNotificationModeProxy) -> FormButtonStyle {
        let accessory: FormRowAccessory
        
        if context.viewState.isApplyingCustomMode, context.viewState.isSelected(mode) {
            accessory = .progressView
        } else {
            accessory = .singleSelection(isSelected: context.viewState.isSelected(mode))
        }
        return FormButtonStyle(accessory: accessory)
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
