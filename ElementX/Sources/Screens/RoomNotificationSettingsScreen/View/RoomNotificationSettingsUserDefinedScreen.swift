//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomNotificationSettingsUserDefinedScreen: View {
    @ObservedObject var context: RoomNotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            RoomNotificationSettingsCustomSectionView(context: context)
            
            deleteButton
        }
        .compoundList()
        .navigationTitle(context.viewState.navigationTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .RoomNotifications)
    }
    
    // MARK: - Private
    
    private var deleteButton: some View {
        ListRow(label: .action(title: L10n.screenRoomNotificationSettingsEditRemoveSetting,
                               icon: \.delete,
                               role: .destructive),
                details: context.viewState.deletingCustomSetting ? .isWaiting(true) : nil,
                kind: .button {
                    context.send(viewAction: .deleteCustomSettingTapped)
                })
                .disabled(context.viewState.deletingCustomSetting)
    }
}

// MARK: - Previews

struct RoomNotificationSettingsUserDefinedScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: true))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: true)
    }()
    
    static let viewModelUnencrypted = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: false))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: true)
    }()

    static var previews: some View {
        RoomNotificationSettingsUserDefinedScreen(context: viewModel.context)
            .previewDisplayName("Encrypted")
        RoomNotificationSettingsUserDefinedScreen(context: viewModelUnencrypted.context)
            .previewDisplayName("Unencrypted")
    }
}
