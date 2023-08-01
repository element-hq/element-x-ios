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

struct NotificationSettingsScreen: View {
    @ObservedObject var context: NotificationSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            if context.viewState.showSystemNotificationsAlert {
                userPermissionSection
            }
            enableNotificationSection
            if context.enableNotifications {
                roomsNotificationSection
                if context.viewState.settings?.roomMentionsEnabled != nil {
                    mentionsSection
                }
                if context.viewState.settings?.callsEnabled != nil {
                    callsSection
                }
            }
        }
        .compoundForm()
        .navigationTitle(L10n.screenNotificationSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .track(screen: .settingsNotifications)
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
            HStack(alignment: .firstTextBaseline, spacing: 13) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.compound.iconTertiaryAlpha)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.screenNotificationSettingsSystemNotificationsTurnedOff)
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                    Text(context.viewState.strings.changeYourSystemSettings)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .tint(.compound.textPrimary)
                        .environment(\.openURL, OpenURLAction { url in
                            context.send(viewAction: .linkClicked(url: url))
                            return .systemAction
                        })
                }
                .padding(.vertical, 5)
            }
        }
        .compoundFormSection()
    }
    
    private var enableNotificationSection: some View {
        Section {
            Toggle(isOn: $context.enableNotifications) {
                Text(L10n.screenNotificationSettingsEnableNotifications)
            }
            .toggleStyle(.compoundForm)
            .onChange(of: context.enableNotifications) { _ in
                context.send(viewAction: .changedEnableNotifications)
            }
        }
        .compoundFormSection()
    }
    
    private var roomsNotificationSection: some View {
        Section {
            // Group chats
            Button {
                context.send(viewAction: .groupChatsTapped)
            } label: {
                LabeledContent {
                    if let settings = context.viewState.settings {
                        Text(context.viewState.strings.string(for: settings.groupChatsMode))
                    } else {
                        ProgressView()
                    }
                } label: {
                    Text(L10n.screenNotificationSettingsGroupChats)
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            .buttonStyle(.compoundForm(accessory: context.viewState.settings.flatMap { _ in .navigationLink }))
            .disabled(context.viewState.settings == nil)
            
            // Direct chats
            Button {
                context.send(viewAction: .directChatsTapped)
            } label: {
                LabeledContent {
                    if let settings = context.viewState.settings {
                        Text(context.viewState.strings.string(for: settings.directChatsMode))
                    } else {
                        ProgressView()
                    }
                } label: {
                    Text(L10n.screenNotificationSettingsDirectChats)
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            .buttonStyle(.compoundForm(accessory: context.viewState.settings.flatMap { _ in .navigationLink }))
            .disabled(context.viewState.settings == nil)
            
        } header: {
            Text(L10n.screenNotificationSettingsNotificationSectionTitle)
                .compoundFormSectionHeader()
        }
        .compoundFormSection()
    }
        
    private var mentionsSection: some View {
        Section {
            Toggle(isOn: $context.roomMentionsEnabled) {
                Text(L10n.screenNotificationSettingsRoomMentionLabel)
            }
            .toggleStyle(.compoundForm)
            .onChange(of: context.roomMentionsEnabled) { _ in
                context.send(viewAction: .roomMentionChanged)
            }
            .disabled(context.viewState.settings?.roomMentionsEnabled == nil)
            .allowsHitTesting(!context.viewState.applyingChange)
        } header: {
            Text(L10n.screenNotificationSettingsMentionsSectionTitle)
                .compoundFormSectionHeader()
        }
        .compoundFormSection()
    }
    
    private var callsSection: some View {
        Section {
            Toggle(isOn: $context.callsEnabled) {
                Text(L10n.screenNotificationSettingsCallsLabel)
            }
            .toggleStyle(.compoundForm)
            .onChange(of: context.callsEnabled) { _ in
                context.send(viewAction: .callsChanged)
            }
            .disabled(context.viewState.settings?.callsEnabled == nil)
            .allowsHitTesting(!context.viewState.applyingChange)
        } header: {
            Text(L10n.screenNotificationSettingsAdditionalSettingsSectionTitle)
                .compoundFormSectionHeader()
        }
        .compoundFormSection()
    }
}

// MARK: - Previews

struct NotificationSettingsScreen_Previews: PreviewProvider {
    static let viewModel: NotificationSettingsScreenViewModel = {
        let appSettings = AppSettings()
        let notificationCenter = UserNotificationCenterMock()
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure = { isEncrypted, activeMembersCount in
            switch (isEncrypted, activeMembersCount) {
            case (_, 2):
                return .allMessages
            default:
                return .mentionsAndKeywordsOnly
            }
        }
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = false

        var viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                            userNotificationCenter: notificationCenter,
                                                            notificationSettingsProxy: notificationSettingsProxy,
                                                            isModallyPresented: true)
        viewModel.fetchInitialContent()
        return viewModel
    }()

    static var previews: some View {
        NotificationSettingsScreen(context: viewModel.context)
    }
}
