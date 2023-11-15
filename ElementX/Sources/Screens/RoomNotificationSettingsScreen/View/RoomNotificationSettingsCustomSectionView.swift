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

struct RoomNotificationSettingsCustomSectionView: View {
    @ObservedObject var context: RoomNotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Section {
            ForEach(context.viewState.availableCustomRoomNotificationModes, id: \.self) { mode in
                ListRow(label: .plain(title: context.viewState.strings.string(for: mode),
                                      description: context.viewState.description(mode: mode)),
                        details: (context.viewState.pendingCustomMode == mode) ? .isWaiting(true) : nil,
                        kind: .selection(isSelected: context.viewState.isSelected(mode: mode)) {
                            context.send(viewAction: .setCustomMode(mode))
                        })
                        .disabled(context.viewState.pendingCustomMode != nil)
            }
        } header: {
            Text(context.viewState.customSettingsSectionHeader)
                .compoundListSectionHeader()
        }
    }
}

struct RoomNotificationSettingsCustomSectionView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))
        
        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: true, joinedMembersCount: 4))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()
    
    static let viewModelUnencrypted = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))
        
        let roomProxy = RoomProxyMock(with: .init(displayName: "Room", isEncrypted: false, joinedMembersCount: 4))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()
    
    static var previews: some View {
        Form {
            RoomNotificationSettingsCustomSectionView(context: viewModel.context)
        }
        .compoundForm()
        .previewDisplayName("Encrypted")
        
        Form {
            RoomNotificationSettingsCustomSectionView(context: viewModelUnencrypted.context)
        }
        .compoundForm()
        .previewDisplayName("Unencrypted")
    }
}
