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

struct NotificationSettingsEditScreen: View {
    @ObservedObject var context: NotificationSettingsEditScreenViewModel.Context
    
    var body: some View {
        Form {
            notificationModeSection
            
            if context.viewState.displayRoomsWithCustomSettings {
                roomsWithCustomSettingsSection
            }
        }
        .compoundList()
        .navigationTitle(context.viewState.strings.navigationTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .settingsDefaultNotifications)
    }
    
    // MARK: - Private

    private var notificationModeSection: some View {
        Section {
            ForEach(context.viewState.availableDefaultModes, id: \.self) { mode in
                ListRow(label: .plain(title: context.viewState.strings.string(for: mode),
                                      description: context.viewState.description(for: mode)),
                        details: (context.viewState.pendingMode == mode) ? .isWaiting(true) : nil,
                        kind: .selection(isSelected: context.viewState.isSelected(mode: mode)) {
                            context.send(viewAction: .setMode(mode))
                        })
                        .disabled(context.viewState.pendingMode != nil)
            }
        } header: {
            Text(context.viewState.strings.modeSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var roomsWithCustomSettingsSection: some View {
        Section {
            ForEach(context.viewState.roomsWithUserDefinedMode, id: \.id) { room in
                NotificationSettingsEditScreenRoomCell(room: room, context: context)
            }
        } header: {
            Text(L10n.screenNotificationSettingsEditCustomSettingsSectionTitle)
                .compoundListSectionHeader()
        }
    }
}

// MARK: - Previews

struct NotificationSettingsEditScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModelGroupChats: NotificationSettingsEditScreenViewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
        
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = [RoomSummary].mockRooms.compactMap(\.id)
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@alice:example.com",
                                                                       roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms))),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        var viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        viewModel.fetchInitialContent()
        return viewModel
    }()
    
    static let viewModelDirectChats: NotificationSettingsEditScreenViewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = []
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@alice:example.com",
                                                                       roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms))),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        var viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        viewModel.fetchInitialContent()
        return viewModel
    }()
    
    static let viewModelDirectApplyingChange: NotificationSettingsEditScreenViewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = []
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe"), mediaProvider: MockMediaProvider(), voiceMessageMediaManager: VoiceMessageMediaManagerMock())

        var viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        viewModel.state.pendingMode = .mentionsAndKeywordsOnly
        viewModel.fetchInitialContent()
        return viewModel
    }()
    
    static let viewModelGroupChatsWithouDisclaimer: NotificationSettingsEditScreenViewModel = {
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init(canHomeserverPushEncryptedEvents: true))
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
        
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = [RoomSummary].mockRooms.compactMap(\.id)
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@alice:example.com",
                                                                       roomSummaryProvider: MockRoomSummaryProvider(state: .loaded(.mockRooms))),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        var viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        viewModel.fetchInitialContent()
        return viewModel
    }()
    
    static var previews: some View {
        NotificationSettingsEditScreen(context: viewModelGroupChats.context)
            .previewDisplayName("Group Chats")
        NotificationSettingsEditScreen(context: viewModelDirectChats.context)
            .previewDisplayName("Direct Chats")
        NotificationSettingsEditScreen(context: viewModelDirectApplyingChange.context)
            .previewDisplayName("Applying change")
        NotificationSettingsEditScreen(context: viewModelGroupChatsWithouDisclaimer.context)
            .previewDisplayName("Group Chats Without Disclaimer")
    }
}
