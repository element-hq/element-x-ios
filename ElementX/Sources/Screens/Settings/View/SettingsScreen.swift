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

struct SettingsScreen: View {
    @State private var showingLogoutConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = ServiceLocator.shared.settings

    @ScaledMetric private var avatarSize = AvatarSize.user(on: .settings).value
    @ScaledMetric private var menuIconSize = 30.0
    private let listRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    
    @ObservedObject var context: SettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            userSection
                .listRowBackground(rowBackgroundColor)
            
            if context.viewState.showSessionVerificationSection {
                sessionVerificationSection
                    .listRowBackground(rowBackgroundColor)
            }
            
            simplifiedSection
                .listRowBackground(rowBackgroundColor)
            
            signOutSection
                .listRowBackground(rowBackgroundColor)
        }
        .introspectTableView { tableView in
            tableView.backgroundColor = .clear
        }
        .navigationTitle(ElementL10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundColor, ignoresSafeAreaEdges: .all)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeButton
            }
        }
    }

    private var versionText: some View {
        Text(ElementL10n.settingsVersion + ": " + InfoPlistReader.target.bundleShortVersionString + " (" + InfoPlistReader.target.bundleVersion + ")")
    }

    private var backgroundColor: Color {
        .element.system
    }

    private var rowBackgroundColor: Color {
        colorScheme == .light ? .element.background : .element.system
    }

    private var userSection: some View {
        Section {
            HStack(spacing: 13) {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .settings),
                                    imageProvider: context.imageProvider)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.viewState.userDisplayName ?? "")
                        .font(.element.title3)
                        .foregroundColor(.element.primaryContent)
                    Text(context.viewState.userID)
                        .font(.element.subheadline)
                        .foregroundColor(.element.primaryContent)
                }
            }
            .listRowInsets(listRowInsets)
        }
    }
    
    private var sessionVerificationSection: some View {
        Section {
            SettingsDefaultRow(title: ElementL10n.settingsSessionVerification,
                               image: Image(systemName: "checkmark.shield")) {
                context.send(viewAction: .sessionVerification)
            }
            .accessibilityIdentifier("sessionVerificationButton")
        }
    }
    
    private var simplifiedSection: some View {
        Section {
            SettingsPickerRow(title: ElementL10n.settingsTimelineStyle,
                              image: Image(systemName: "rectangle.grid.1x2"),
                              selection: $settings.timelineStyle) {
                ForEach(TimelineStyle.allCases, id: \.self) { style in
                    Text(style.description)
                        .tag(style)
                }
            }
            .accessibilityIdentifier("timelineStylePicker")
            
            SettingsDefaultRow(title: ElementL10n.sendBugReport,
                               image: Image(systemName: "questionmark.circle")) {
                context.send(viewAction: .reportBug)
            }
            .accessibilityIdentifier("reportBugButton")
        }
    }
    
    private var signOutSection: some View {
        Section {
            SettingsDefaultRow(title: ElementL10n.actionSignOut,
                               image: Image(systemName: "rectangle.portrait.and.arrow.right")) {
                showingLogoutConfirmation = true
            }
            .accessibilityIdentifier("logoutButton")
            .alert(ElementL10n.actionSignOut,
                   isPresented: $showingLogoutConfirmation) {
                Button(ElementL10n.actionSignOut,
                       role: .destructive,
                       action: logout)
            } message: {
                Text(ElementL10n.actionSignOutConfirmationSimple)
            }
        } footer: {
            VStack {
                versionText
                    .font(.element.caption1)
                    .foregroundColor(.element.tertiaryContent)
                    .frame(maxWidth: .infinity)
                
                if let deviceId = context.viewState.deviceID {
                    Text(deviceId)
                        .font(.element.caption1)
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .padding(.top, 24)
        }
    }

    private var closeButton: some View {
        Button(ElementL10n.actionCancel, action: close)
            .accessibilityIdentifier("closeButton")
    }

    private func close() {
        context.send(viewAction: .close)
    }

    private func logout() {
        context.send(viewAction: .logout)
    }
}

extension TimelineStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .plain:
            return ElementL10n.roomTimelineStylePlainLongDescription
        case .bubbles:
            return ElementL10n.roomTimelineStyleBubbledLongDescription
        }
    }
}

// MARK: - Previews

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let viewModel = SettingsScreenViewModel(withUserSession: userSession)
        
        NavigationView {
            SettingsScreen(context: viewModel.context)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
