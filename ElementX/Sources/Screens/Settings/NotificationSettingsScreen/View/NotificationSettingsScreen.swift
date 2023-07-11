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
        }
        .compoundForm()
        .navigationTitle(L10n.screenNotificationSettingsTitle)
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
}

// MARK: - Previews

struct NotificationSettingsScreen_Previews: PreviewProvider {
    static let viewModel: NotificationSettingsScreenViewModel = {
        let appSettings = AppSettings()
        let notificationCenter = UserNotificationCenterMock()
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        var viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings, userNotificationCenter: notificationCenter)
        return viewModel
    }()

    static var previews: some View {
        NotificationSettingsScreen(context: viewModel.context)
    }
}
