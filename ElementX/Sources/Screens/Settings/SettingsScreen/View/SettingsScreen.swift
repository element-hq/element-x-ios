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
        .compoundList()
        .navigationTitle(L10n.commonSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                doneButton
            }
        }
        .introspect(.window, on: .iOS(.v16, .v17)) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }

    private var versionText: Text {
        Text(L10n.settingsVersionNumber(InfoPlistReader.main.bundleShortVersionString, InfoPlistReader.main.bundleVersion))
    }

    private var userSection: some View {
        Section {
            ListRow(kind: .custom {
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
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, 8)
            })
        }
    }
    
    private var sessionVerificationSection: some View {
        Section {
            ListRow(label: .default(title: L10n.actionCompleteVerification,
                                    systemIcon: .checkmarkShield),
                    kind: .button { context.send(viewAction: .sessionVerification) })
        }
    }
    
    private var developerOptionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonDeveloperOptions,
                                    systemIcon: .hammerCircle),
                    kind: .navigationLink {
                        context.send(viewAction: .developerOptions)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
        }
    }
    
    private var simplifiedSection: some View {
        Section {
            // Account
            if context.viewState.accountURL != nil {
                ListRow(label: .default(title: L10n.screenSettingsOidcAccount,
                                        systemIcon: .person),
                        kind: .button {
                            context.send(viewAction: .account)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.account)
            }
            
            // Message layout
            ListRow(label: .default(title: L10n.commonMessageLayout,
                                    systemIcon: .rectangleGrid1x2),
                    kind: .picker(selection: $context.timelineStyle,
                                  items: TimelineStyle.allCases.map { (title: $0.name, tag: $0) }))
                .accessibilityIdentifier("timelineStylePicker")
                .onChange(of: context.timelineStyle) { _ in
                    context.send(viewAction: .changedTimelineStyle)
                }
            
            // Notifications
            if context.viewState.showNotificationSettings {
                ListRow(label: .default(title: L10n.screenNotificationSettingsTitle,
                                        systemIcon: .bell),
                        kind: .navigationLink {
                            context.send(viewAction: .notifications)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            }
            
            // Analytics
            ListRow(label: .default(title: L10n.commonAnalytics,
                                    systemIcon: .chartBar),
                    kind: .navigationLink {
                        context.send(viewAction: .analytics)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            
            // Report Bug
            ListRow(label: .default(title: L10n.commonReportABug,
                                    systemIcon: .ladybug),
                    kind: .navigationLink {
                        context.send(viewAction: .reportBug)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.reportBug)
            
            // About
            ListRow(label: .default(title: L10n.commonAbout,
                                    systemIcon: .questionmarkCircle),
                    kind: .navigationLink {
                        context.send(viewAction: .about)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.about)
        }
    }
    
    private var signOutSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenSignoutPreferenceItem,
                                    systemIcon: .rectanglePortraitAndArrowRight),
                    kind: .button {
                        showingLogoutConfirmation = true
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.logout)
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
                
                if let deviceID = context.viewState.deviceID {
                    Text(deviceID)
                }
            }
            .compoundListSectionFooter()
            .textSelection(.enabled)
            .padding(.top, 24)
        }
    }

    private var doneButton: some View {
        Button(L10n.actionDone, action: close)
            .accessibilityIdentifier(A11yIdentifiers.settingsScreen.done)
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
        let verificationController = SessionVerificationControllerProxyMock()
        verificationController.isVerified = false
        let userSession = MockUserSession(sessionVerificationController: verificationController,
                                          clientProxy: MockClientProxy(userID: "@userid:example.com",
                                                                       deviceID: "AAAAAAAAAAA",
                                                                       accountURL: "https://matrix.org/account"),
                                          mediaProvider: MockMediaProvider())
        ServiceLocator.shared.settings.notificationSettingsEnabled = true
        return SettingsScreenViewModel(userSession: userSession,
                                       appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        NavigationStack {
            SettingsScreen(context: viewModel.context)
        }
    }
}
