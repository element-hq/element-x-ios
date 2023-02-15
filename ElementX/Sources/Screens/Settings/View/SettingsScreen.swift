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

    @ScaledMetric private var avatarSize = AvatarSize.user(on: .settings).value
    @ScaledMetric private var menuIconSize = 30.0
    
    private let listRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    
    @ObservedObject var context: SettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            userSection
                .listRowBackground(Color.element.formRowBackground)
            
            if context.viewState.showSessionVerificationSection {
                sessionVerificationSection
                    .listRowBackground(Color.element.formRowBackground)
            }
            
            simplifiedSection
                .listRowBackground(Color.element.formRowBackground)
            
            signOutSection
                .listRowBackground(Color.element.formRowBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(ElementL10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                doneButton
            }
        }
    }

    private var versionText: some View {
        Text(ElementL10n.settingsVersion + ": " + InfoPlistReader.main.bundleShortVersionString + " (" + InfoPlistReader.main.bundleVersion + ")")
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
        }
    }
    
    private var simplifiedSection: some View {
        Section {
            SettingsPickerRow(title: ElementL10n.settingsTimelineStyle,
                              image: Image(systemName: "rectangle.grid.1x2"),
                              selection: $context.timelineStyle) {
                ForEach(TimelineStyle.allCases, id: \.self) { style in
                    Text(style.name)
                        .tag(style)
                }
            }
            .accessibilityIdentifier("timelineStylePicker")
            .onChange(of: context.timelineStyle) { _ in
                context.send(viewAction: .changedTimelineStyle)
            }
            
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

    private var doneButton: some View {
        Button(ElementL10n.done, action: close)
    }

    private func close() {
        context.send(viewAction: .close)
    }

    private func logout() {
        context.send(viewAction: .logout)
    }
}

private extension TimelineStyle {
    var name: String {
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
                .tint(.element.accent)
        }
    }
}
