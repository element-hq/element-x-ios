//
// Copyright 2023 New Vector Ltd
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

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: true)
    }()
    
    static let viewModelUnencrypted = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: false))
        
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
