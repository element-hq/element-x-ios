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

struct SettingsScreen: View {
    @State private var showingLogoutConfirmation = false
    
    @ObservedObject var context: SettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            userSection
            
            if context.viewState.showSessionVerificationSection {
                sessionVerificationSection
            }
            
            simplifiedSection
            
            if context.viewState.showDeveloperOptions {
                developerOptionsSection
            }
            
            signOutSection
        }
        .compoundForm()
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
            HStack(spacing: 12) {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .settings),
                                    imageProvider: context.imageProvider)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.viewState.userDisplayName ?? "")
                        .font(.compound.headingMD)
                        .foregroundColor(.compound.textPrimary)
                    Text(context.viewState.userID)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .compoundFormSection()
    }
    
    private var sessionVerificationSection: some View {
        Section {
            Button { context.send(viewAction: .sessionVerification) } label: {
                Label(ElementL10n.settingsSessionVerification, systemImage: "checkmark.shield")
            }
            .buttonStyle(.compoundForm())
        }
        .compoundFormSection()
    }
    
    private var developerOptionsSection: some View {
        Section {
            Button { context.send(viewAction: .developerOptions) } label: {
                Label(ElementL10n.settingsDeveloperOptions, systemImage: "hammer.circle")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("sessionVerificationButton")
        }
        .compoundFormSection()
    }
    
    private var simplifiedSection: some View {
        Section {
            Picker(selection: $context.timelineStyle) {
                ForEach(TimelineStyle.allCases, id: \.self) { style in
                    Text(style.name)
                        .tag(style)
                }
            } label: {
                Label(ElementL10n.settingsTimelineStyle, systemImage: "rectangle.grid.1x2")
            }
            .labelStyle(.compoundFormRow())
            .accessibilityIdentifier("timelineStylePicker")
            .onChange(of: context.timelineStyle) { _ in
                context.send(viewAction: .changedTimelineStyle)
            }
            
            Button { context.send(viewAction: .reportBug) } label: {
                Label(ElementL10n.sendBugReport, systemImage: "questionmark.circle")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("reportBugButton")
        }
        .compoundFormSection()
    }
    
    private var signOutSection: some View {
        Section {
            Button { showingLogoutConfirmation = true } label: {
                Label(L10n.actionSignOut, systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.compoundForm())
            .accessibilityIdentifier("logoutButton")
            .alert(L10n.actionSignOut, isPresented: $showingLogoutConfirmation) {
                Button(L10n.actionSignOut,
                       role: .destructive,
                       action: logout)
            } message: {
                Text(L10n.actionSignOutConfirmation)
            }
        } footer: {
            VStack {
                versionText
                    .frame(maxWidth: .infinity)
                
                context.viewState.deviceID.map(Text.init)
            }
            .compoundFormSectionFooter()
            .padding(.top, 24)
        }
        .compoundFormSection()
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
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        return SettingsScreenViewModel(withUserSession: userSession)
    }()
    
    static var previews: some View {
        NavigationStack {
            SettingsScreen(context: viewModel.context)
        }
    }
}
