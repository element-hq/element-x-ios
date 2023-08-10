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

import SwiftUI

struct RoomNotificationSettingsCustomModeScreen: View {
    @ObservedObject var context: RoomNotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            RoomNotificationSettingsCustomSectionView(context: context)
            
            Button(role: .destructive) {
                context.send(viewAction: .deleteCustomSettingTapped)
            } label: {
                LabeledContent {
                    if context.viewState.deletingCustomSetting {
                        ProgressView()
                    } else {
                        EmptyView()
                    }
                } label: {
                    Label(UntranslatedL10n.screenRoomNotificationSettingsEditRemoveSetting, systemImage: "trash")
                }
            }
            .buttonStyle(.compoundForm())
            .disabled(context.viewState.deletingCustomSetting)
        }
        .compoundForm()
        .navigationTitle(context.viewState.navigationTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .roomNotifications)
    }
}

// MARK: - Previews

struct RoomNotificationSettingsCustomModeScreen_Previews: PreviewProvider {
    static let viewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .mentionsAndKeywordsOnly, roomMode: .mentionsAndKeywordsOnly))

        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        let model = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                            roomProxy: roomProxy,
                                                            displayAsGlobalCustomRoomSettings: true)
        
        return model
    }()

    static var previews: some View {
        RoomNotificationSettingsCustomModeScreen(context: viewModel.context)
    }
}
