//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SFSafeSymbols
import SwiftUI

struct SettingsScreen: View {
    let context: SettingsScreenViewModel.Context
    
    private var shouldHideManageAccountSection: Bool {
        // Always shown: the Two-step verification row lives in this section.
        false
    }
    
    var body: some View {
        Form {
            userSection
            
            manageMyAppSection
            
            if !shouldHideManageAccountSection {
                manageAccountSection
            }
            
            generalSection
            
            signOutSection
            
            if context.viewState.showDeveloperOptions {
                developerOptionsSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    private var userSection: some View {
        Section {
            ListRow(kind: .custom {
                Button {
                    context.send(viewAction: .userDetails)
                } label: {
                    HStack(spacing: 12) {
                        LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                            name: context.viewState.userDisplayName,
                                            contentID: context.viewState.userID,
                                            avatarSize: .user(on: .settings),
                                            mediaProvider: context.mediaProvider)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.viewState.userDisplayName ?? "")
                                .font(.compound.headingMD)
                                .foregroundColor(.compound.textPrimary)
                            Text(context.viewState.userLocalpart)
                                .font(.compound.bodySM)
                                .foregroundColor(.compound.textSecondary)
                        }
                        
                        Spacer()
                        
                        ListRowAccessory.navigationLink
                    }
                    .padding(.horizontal, ListRowPadding.horizontal)
                    .padding(.vertical, 8)
                }
            })
        }
    }
    
    private var manageMyAppSection: some View {
        Section {
            // GUA FORK: Find which of the user's phone contacts are already on Gua.
            ListRow(label: .default(title: "Find friends",
                                    icon: \.userAdd),
                    kind: .navigationLink {
                        context.send(viewAction: .findFriends)
                    })

            ListRow(label: .default(title: L10n.screenNotificationSettingsTitle,
                                    icon: \.notifications),
                    kind: .navigationLink {
                        context.send(viewAction: .notifications)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            
            ListRow(label: .default(title: L10n.commonScreenLock,
                                    icon: \.lock),
                    kind: .navigationLink {
                        context.send(viewAction: .appLock)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.screenLock)
            
            // GUA FORK: The Encryption (secure backup / key storage / recovery)
            // entry point is intentionally hidden when `hidesAdvancedEncryption`
            // is set. End-to-end encryption stays fully on with safe defaults —
            // key storage and recovery are managed automatically — but the advanced
            // cryptographic controls are not surfaced to non-technical users.
            // (Engine logic in the view model is left untouched so encryption
            // keeps working in the background.)
            if !context.viewState.hidesAdvancedEncryption {
                switch context.viewState.securitySectionMode {
                case .secureBackup:
                    ListRow(label: .default(title: L10n.commonEncryption,
                                            icon: \.key),
                            details: context.viewState.showSecuritySectionBadge ? .icon(securitySectionBadge) : nil,
                            kind: .navigationLink { context.send(viewAction: .secureBackup) })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.secureBackup)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    private var manageAccountSection: some View {
        Section {
            if let url = context.viewState.accountProfileURL {
                ListRow(label: .default(title: L10n.actionManageAccount,
                                        icon: \.userProfile),
                        kind: .button {
                            context.send(viewAction: .manageAccount(url: url))
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.account)
            }
            
            if let url = context.viewState.accountSessionsListURL {
                ListRow(label: .default(title: L10n.actionManageDevices,
                                        icon: \.devices),
                        kind: .button {
                            context.send(viewAction: .manageAccount(url: url))
                        })
            }
            
            // GUA FORK: Two-step verification entry point
            ListRow(label: .default(title: L10n.screenTwoStepVerificationTitle,
                                    icon: \.lockSolid),
                    kind: .navigationLink {
                        context.send(viewAction: .twoStepVerification)
                    })
            
            if context.viewState.showBlockedUsers {
                ListRow(label: .default(title: L10n.commonBlockedUsers,
                                        icon: \.block),
                        kind: .navigationLink {
                            context.send(viewAction: .blockedUsers)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.blockedUsers)
            }
        }
    }
    
    private var generalSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonAbout,
                                    icon: \.info),
                    kind: .navigationLink {
                        context.send(viewAction: .about)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.about)
            
            if context.viewState.isBugReportServiceEnabled {
                ListRow(label: .default(title: L10n.commonReportAProblem,
                                        icon: \.chatProblem),
                        kind: .navigationLink {
                            context.send(viewAction: .reportBug)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.reportBug)
            }
            
            if context.viewState.showAnalyticsSettings {
                ListRow(label: .default(title: L10n.commonAnalytics,
                                        icon: \.chart),
                        kind: .navigationLink {
                            context.send(viewAction: .analytics)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            }
            
            ListRow(label: .default(title: L10n.commonAdvancedSettings,
                                    icon: \.settings),
                    kind: .navigationLink {
                        context.send(viewAction: .advancedSettings)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.advancedSettings)
        }
    }
    
    private var signOutSection: some View {
        Section {
            ListRow(label: .action(title: L10n.screenSignoutPreferenceItem,
                                   icon: \.signOut,
                                   role: .destructive),
                    kind: .button {
                        context.send(viewAction: .logout)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.logout)
            
            if context.viewState.showAccountDeactivation {
                ListRow(label: .action(title: L10n.actionDeactivateAccount,
                                       icon: \.warning,
                                       role: .destructive),
                        kind: .navigationLink {
                            context.send(viewAction: .deactivateAccount)
                        })
            }
        } footer: {
            if !context.viewState.showDeveloperOptions {
                versionSection
            }
        }
    }
    
    private var developerOptionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonDeveloperOptions,
                                    icon: \.code),
                    kind: .navigationLink {
                        context.send(viewAction: .developerOptions)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
        } footer: {
            versionSection
        }
    }
    
    private var versionSection: some View {
        VStack(spacing: 0) {
            versionText
                .frame(maxWidth: .infinity)
            
            if let deviceID = context.viewState.deviceID {
                Text(deviceID)
            }
        }
        .compoundListSectionFooter()
        .textSelection(.enabled)
        .padding(.top, 24)
        .onTapGesture(count: 7) {
            context.send(viewAction: .enableDeveloperOptions)
        }
    }
    
    private var versionText: Text {
        Text(L10n.settingsVersionNumber(InfoPlistReader.main.bundleShortVersionString, InfoPlistReader.main.bundleVersion))
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionDone) { context.send(viewAction: .close) }
                .accessibilityIdentifier(A11yIdentifiers.settingsScreen.done)
        }
    }
    
    @ViewBuilder
    private var securitySectionBadge: some View {
        if context.viewState.showSecuritySectionBadge {
            BadgeView(size: 10)
        }
    }
}

// MARK: - Previews

struct SettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let bugReportDisabledViewModel = makeViewModel(isBugReportServiceEnabled: false)
    
    static var previews: some View {
        NavigationStack {
            SettingsScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.accountSessionsListURL).map { $0 != nil }.eraseToStream())
        .previewDisplayName("Default")
        
        NavigationStack {
            SettingsScreen(context: bugReportDisabledViewModel.context)
        }
        .snapshotPreferences(expect: bugReportDisabledViewModel.context.observe(\.viewState.accountSessionsListURL).map { $0 != nil }.eraseToStream())
        .previewDisplayName("Bug report disabled")
    }
    
    static func makeViewModel(isBugReportServiceEnabled: Bool = true) -> SettingsScreenViewModel {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com",
                                                                                   deviceID: "AAAAAAAAAAA"))))
        return SettingsScreenViewModel(userSession: userSession,
                                       appSettings: ServiceLocator.shared.settings,
                                       isBugReportServiceEnabled: isBugReportServiceEnabled)
    }
}
