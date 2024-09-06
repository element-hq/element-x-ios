//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: true))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()

    static let viewModelCustom = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: true))
        
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
