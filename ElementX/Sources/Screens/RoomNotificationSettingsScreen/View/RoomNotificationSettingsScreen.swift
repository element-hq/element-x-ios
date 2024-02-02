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

import Compound
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
        .compoundList()
        .navigationTitle(context.viewState.navigationTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .RoomNotifications)
    }
    
    // MARK: - Private

    private var allowCustomSettingSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenRoomNotificationSettingsAllowCustom),
                    kind: .toggle($context.allowCustomSetting))
                .accessibilityIdentifier(A11yIdentifiers.roomNotificationSettingsScreen.allowCustomSetting)
                .disabled(context.viewState.notificationSettingsState.isLoading)
                .onChange(of: context.allowCustomSetting) { _ in
                    context.send(viewAction: .changedAllowCustomSettings)
                }
        } footer: {
            Text(L10n.screenRoomNotificationSettingsAllowCustomFootnote)
                .compoundListSectionFooter()
        }
    }
    
    private var defaultSettingSection: some View {
        Section {
            ListRow(label: .plain(title: context.viewState.isRestoringDefaultSetting ? L10n.commonLoading : context.viewState.strings.string(for: context.viewState.notificationSettingsState)),
                    kind: .label)
                .disabled(context.viewState.isRestoringDefaultSetting)
        } header: {
            Text(L10n.screenRoomNotificationSettingsDefaultSettingTitle)
                .compoundListSectionHeader()
        } footer: {
            Text(context.viewState.strings.customSettingFootnote)
                .environment(\.openURL, OpenURLAction { url in
                    guard url == context.viewState.strings.customSettingFootnoteLink else { return .discarded }
                    context.send(viewAction: .customSettingFootnoteLinkTapped)
                    return .handled
                })
                .compoundListSectionFooter()
        }
    }
    
    private var customSettingsSection: some View {
        RoomNotificationSettingsCustomSectionView(context: context)
    }
}

// MARK: - Previews

struct RoomNotificationSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()

    static let viewModelCustom = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()
    
    static var previews: some View {
        RoomNotificationSettingsScreen(context: viewModel.context)
            .previewDisplayName("Default")
        RoomNotificationSettingsScreen(context: viewModelCustom.context)
            .previewDisplayName("Custom")
    }
}
