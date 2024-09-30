//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: true))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()
    
    static let viewModelUnencrypted = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(defaultRoomMode: .allMessages, roomMode: .mentionsAndKeywordsOnly))
        
        let roomProxy = JoinedRoomProxyMock(.init(name: "Room", isEncrypted: false))
        
        return RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxy,
                                                       roomProxy: roomProxy,
                                                       displayAsUserDefinedRoomSettings: false)
    }()
    
    static var previews: some View {
        Form {
            RoomNotificationSettingsCustomSectionView(context: viewModel.context)
        }
        .compoundList()
        .previewDisplayName("Encrypted")
        
        Form {
            RoomNotificationSettingsCustomSectionView(context: viewModelUnencrypted.context)
        }
        .compoundList()
        .previewDisplayName("Unencrypted")
    }
}
