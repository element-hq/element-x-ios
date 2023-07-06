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
        .navigationTitle(L10n.commonSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                doneButton
            }
        }
    }

    private var versionText: some View {
        Text(L10n.settingsVersionNumber(InfoPlistReader.main.bundleShortVersionString, InfoPlistReader.main.bundleVersion))
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
                Label(L10n.actionCompleteVerification, systemImage: "checkmark.shield")
            }
            .buttonStyle(.compoundForm())
        }
        .compoundFormSection()
    }
    
    private var developerOptionsSection: some View {
        Section {
            Button { context.send(viewAction: .developerOptions) } label: {
                Label(L10n.commonDeveloperOptions, systemImage: "hammer.circle")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("developerOptionsButton")
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
                Label(L10n.commonMessageLayout, systemImage: "rectangle.grid.1x2")
            }
            .labelStyle(.compoundFormRow())
            .accessibilityIdentifier("timelineStylePicker")
            .onChange(of: context.timelineStyle) { _ in
                context.send(viewAction: .changedTimelineStyle)
            }
            
            // Notifications
            if context.viewState.showNotificationsSettings {
                Button { context.send(viewAction: .notifications) } label: {
                    Label(L10n.screenNotificationsSettingsTitle, systemImage: "bell")
                }
                .buttonStyle(.compoundForm(accessory: .navigationLink))
                .accessibilityIdentifier("notificationsButton")
            }
            
            // Analytics
            Button { context.send(viewAction: .analytics) } label: {
                Label(L10n.commonAnalytics, systemImage: "chart.bar")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("analyticsButton")
            
            // Report Bug
            Button { context.send(viewAction: .reportBug) } label: {
                Label(L10n.commonReportABug, systemImage: "ladybug")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("reportBugButton")
            
            // About
            Button { context.send(viewAction: .about) } label: {
                Label(L10n.commonAbout, systemImage: "questionmark.circle")
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .accessibilityIdentifier("aboutButton")
        }
        .compoundFormSection()
    }
    
    private var signOutSection: some View {
        Section {
            Button { showingLogoutConfirmation = true } label: {
                Label(L10n.screenSignoutPreferenceItem, systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.compoundForm())
            .accessibilityIdentifier("logoutButton")
            .alert(L10n.screenSignoutConfirmationDialogTitle, isPresented: $showingLogoutConfirmation) {
                Button(L10n.screenSignoutConfirmationDialogSubmit,
                       role: .destructive,
                       action: logout)
            } message: {
                Text(L10n.screenSignoutConfirmationDialogContent)
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
        Button(L10n.actionDone, action: close)
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
            return L10n.commonModern
        case .bubbles:
            return L10n.commonBubbles
        }
    }
}

// MARK: - Previews

struct SettingsScreen_Previews: PreviewProvider {
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        ServiceLocator.shared.settings.notificationsSettingsEnabled = true
        return SettingsScreenViewModel(userSession: userSession,
                                       appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        NavigationStack {
            SettingsScreen(context: viewModel.context)
        }
    }
}
