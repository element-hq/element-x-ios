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

struct NotificationSettingsScreen: View {
    @ObservedObject var context: NotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            if context.viewState.settings?.inconsistentSettings.isEmpty == false {
                configurationMismatchSection
            } else {
                if context.viewState.showSystemNotificationsAlert {
                    userPermissionSection
                }
                
                enableNotificationSection
                
                if context.enableNotifications {
                    roomsNotificationSection
                    
                    if context.viewState.settings?.roomMentionsEnabled != nil {
                        mentionsSection
                    }
                    
                    if context.viewState.showCallsSettings, context.viewState.settings?.callsEnabled != nil {
                        callsSection
                    }
                    
                    if context.viewState.settings?.invitationsEnabled != nil {
                        additionalSettingsSection
                    }
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenNotificationSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .track(screen: .SettingsNotifications)
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isModallyPresented {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionClose) {
                    context.send(viewAction: .close)
                }
            }
        }
    }
    
    private var userPermissionSection: some View {
        Section {
            ListRow(kind: .custom {
                HStack(alignment: .firstTextBaseline, spacing: 13) {
                    Image(systemSymbol: .exclamationmarkCircleFill)
                        .foregroundColor(.compound.iconTertiaryAlpha)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.screenNotificationSettingsSystemNotificationsTurnedOff)
                            .font(.compound.bodyLG)
                            .foregroundColor(.compound.textPrimary)
                        Text(context.viewState.strings.changeYourSystemSettings)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .tint(.compound.textPrimary)
                    }
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, 8)
            })
        }
    }
    
    private var enableNotificationSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenNotificationSettingsEnableNotifications),
                    kind: .toggle($context.enableNotifications))
                .onChange(of: context.enableNotifications) { _ in
                    context.send(viewAction: .changedEnableNotifications)
                }
        }
    }
    
    private var roomsNotificationSection: some View {
        Section {
            // Group chats
            ListRow(label: .plain(title: L10n.screenNotificationSettingsGroupChats),
                    details: context.viewState.settings.map {
                        .title(context.viewState.strings.string(for: $0.groupChatsMode))
                    } ?? .isWaiting(true),
                    kind: .navigationLink {
                        context.send(viewAction: .groupChatsTapped)
                    })
                    .disabled(context.viewState.settings == nil)
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            
            // Direct chats
            ListRow(label: .plain(title: L10n.screenNotificationSettingsDirectChats),
                    details: context.viewState.settings.map {
                        .title(context.viewState.strings.string(for: $0.directChatsMode))
                    } ?? .isWaiting(true),
                    kind: .navigationLink {
                        context.send(viewAction: .directChatsTapped)
                    })
                    .disabled(context.viewState.settings == nil)
                    .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            
        } header: {
            Text(L10n.screenNotificationSettingsNotificationSectionTitle)
                .compoundListSectionHeader()
        }
    }
        
    private var mentionsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenNotificationSettingsRoomMentionLabel),
                    kind: .toggle($context.roomMentionsEnabled))
                .disabled(context.viewState.settings?.roomMentionsEnabled == nil)
                .allowsHitTesting(!context.viewState.applyingChange)
                .onChange(of: context.roomMentionsEnabled) { _ in
                    context.send(viewAction: .roomMentionChanged)
                }
        } header: {
            Text(L10n.screenNotificationSettingsMentionsSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var callsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenNotificationSettingsCallsLabel),
                    kind: .toggle($context.callsEnabled))
                .disabled(context.viewState.settings?.callsEnabled == nil)
                .allowsHitTesting(!context.viewState.applyingChange)
                .onChange(of: context.callsEnabled) { _ in
                    context.send(viewAction: .callsChanged)
                }
        } header: {
            Text(L10n.screenNotificationSettingsAdditionalSettingsSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var additionalSettingsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenNotificationSettingsInviteForMeLabel),
                    kind: .toggle($context.invitationsEnabled))
                .disabled(context.viewState.settings?.invitationsEnabled == nil)
                .allowsHitTesting(!context.viewState.applyingChange)
                .onChange(of: context.invitationsEnabled) { _ in
                    context.send(viewAction: .invitationsChanged)
                }
        } header: {
            Text(L10n.screenNotificationSettingsAdditionalSettingsSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var configurationMismatchSection: some View {
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.screenNotificationSettingsConfigurationMismatch)
                            .font(.compound.bodyLGSemibold)
                        Text(L10n.screenNotificationSettingsConfigurationMismatchDescription)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                    }
                    Button {
                        context.send(viewAction: .fixConfigurationMismatchTapped)
                    } label: {
                        Text(L10n.actionContinue)
                    }
                    .buttonStyle(.compound(.primary, size: .medium))
                    .disabled(context.viewState.fixingConfigurationMismatch)
                    .accessibilityIdentifier(A11yIdentifiers.notificationSettingsScreen.fixMismatchConfiguration)
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, 24)
            })
        }
    }
}

// MARK: - Previews

struct NotificationSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel: NotificationSettingsScreenViewModel = {
        let appSettings = AppSettings()
        let notificationCenter = UserNotificationCenterMock()
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (_, true):
                return .allMessages
            default:
                return .mentionsAndKeywordsOnly
            }
        }
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = false

        let userSession = MockUserSession(clientProxy: ClientProxyMock(.init(userID: "John Doe")),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())

        var viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                            userNotificationCenter: notificationCenter,
                                                            notificationSettingsProxy: notificationSettingsProxy,
                                                            isModallyPresented: true)
        viewModel.fetchInitialContent()
        return viewModel
    }()
    
    static let viewModelConfigurationMismatch: NotificationSettingsScreenViewModel = {
        let appSettings = AppSettings()
        let notificationCenter = UserNotificationCenterMock()
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (true, true):
                return .allMessages
            case (false, true):
                return .mute
            default:
                return .mentionsAndKeywordsOnly
            }
        }
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = false
        
        let userSession = MockUserSession(clientProxy: ClientProxyMock(.init(userID: "John Doe")),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())

        var viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                            userNotificationCenter: notificationCenter,
                                                            notificationSettingsProxy: notificationSettingsProxy,
                                                            isModallyPresented: true)
        viewModel.fetchInitialContent()
        return viewModel
    }()

    static var previews: some View {
        NotificationSettingsScreen(context: viewModel.context)
            .snapshot(delay: 2.0)
        NotificationSettingsScreen(context: viewModelConfigurationMismatch.context)
            .snapshot(delay: 2.0)
            .previewDisplayName("Configuration mismatch")
    }
}
