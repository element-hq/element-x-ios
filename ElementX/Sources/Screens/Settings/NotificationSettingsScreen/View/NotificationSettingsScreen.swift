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
                mentionsSection
                callsSection
            }
        }
        .compoundForm()
        .navigationTitle(L10n.screenNotificationSettingsTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .settingsNotifications)
    }
    
    // MARK: - Private

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
    
    @ViewBuilder
    private var roomsNotificationSection: some View {
        Section {
            // Group chats
            Button {
                context.send(viewAction: .processTapGroupChats)
            } label: {
                LabeledContent {
                    notificationModeStateView(context.viewState.groupChatNotificationSettingsState)
                } label: {
                    Text(L10n.screenNotificationSettingsGroupChats)
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            .buttonStyle(.compoundForm(accessory: context.viewState.groupChatNotificationSettingsState.isLoaded ? .navigationLink : nil))
            .disabled(context.viewState.groupChatNotificationSettingsState.isLoading)
            
            // Direct chats
            Button {
                context.send(viewAction: .processTapDirectChats)
            } label: {
                LabeledContent {
                    notificationModeStateView(context.viewState.directChatNotificationSettingsState)
                } label: {
                    Text(L10n.screenNotificationSettingsDirectChats)
                }
            }
            .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.notifications)
            .buttonStyle(.compoundForm(accessory: context.viewState.groupChatNotificationSettingsState.isLoaded ? .navigationLink : nil))
            .disabled(context.viewState.groupChatNotificationSettingsState.isLoading)
            
        } header: {
            Text(L10n.screenNotificationSettingsNotificationSectionTitle)
        }
        .compoundFormSection()
    }
        
    @ViewBuilder
    private func notificationModeStateView(_ state: NotificationSettingsScreenModeState) -> some View {
        switch state {
        case .loading:
            ProgressView()
        case .loaded(let mode):
            Text(context.viewState.strings.string(for: mode))
        case .error:
            Image(systemName: "exclamationmark.circle")
        }
    }
    
    @ViewBuilder
    private var mentionsSection: some View {
        Section {
            Toggle(isOn: $context.enableRoomMention) {
                Text(L10n.screenNotificationSettingsRoomMentionLabel)
            }
            .toggleStyle(.compoundForm)
            .onChange(of: context.enableRoomMention) { _ in
                context.send(viewAction: .processToggleRoomMention)
            }
            .allowsHitTesting(!context.viewState.applyingChange)
        } header: {
            Text(L10n.screenNotificationSettingsMentionsSectionTitle)
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var callsSection: some View {
        Section {
            Toggle(isOn: $context.enableCalls) {
                Text(L10n.screenNotificationSettingsCallsLabel)
            }
            .toggleStyle(.compoundForm)
            .onChange(of: context.enableCalls) { _ in
                context.send(viewAction: .processToggleCalls)
            }
            .allowsHitTesting(!context.viewState.applyingChange)
        } header: {
            Text(L10n.screenNotificationSettingsAdditionalSettingsSectionTitle)
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
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = true

        var viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                            userNotificationCenter: notificationCenter,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        viewModel.state.groupChatNotificationSettingsState = .loaded(mode: .allMessages)
        viewModel.state.directChatNotificationSettingsState = .loaded(mode: .mentionsAndKeywordsOnly)
        viewModel.state.bindings.enableRoomMention = true
        return viewModel
    }()

    static var previews: some View {
        NotificationSettingsScreen(context: viewModel.context)
    }
}
