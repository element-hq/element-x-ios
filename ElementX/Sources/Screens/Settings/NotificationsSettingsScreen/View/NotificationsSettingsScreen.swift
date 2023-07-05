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

struct NotificationsSettingsScreen: View {
    @ObservedObject var context: NotificationsSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            enableNotificationSection
        }
        .compoundForm()
        .navigationTitle(UntranslatedL10n.notifications)
        .track(screen: .settingsNotifications)
    }
    
    // MARK: - Private

    @ViewBuilder
    private var enableNotificationSection: some View {
        Section {
            Toggle(isOn: $context.enableNotifications) {
                Text(UntranslatedL10n.notificationsSettingsAllowOnThisDevice)
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
    static let viewModel: NotificationsSettingsScreenViewModel = {
        let appSettings = AppSettings()
        return NotificationsSettingsScreenViewModel(appSettings: appSettings)
    }()

    static var previews: some View {
        NotificationsSettingsScreen(context: viewModel.context)
    }
}
