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
        context.viewState.accountProfileURL == nil &&
            context.viewState.accountSessionsListURL == nil &&
            !context.viewState.showBlockedUsers
    }
    
    var body: some View {
        Form {
            userSection
            
            zeroMenuSection
            
            //            manageMyAppSection
            
            //            if !shouldHideManageAccountSection {
            //                manageAccountSection
            //            }
            //
            //            generalSection
            //
            //            Section {
            //                ZeroListRow(label: .default(title: "Advanced Settings",
            //                                        icon: \.code),
            //                        kind: .navigationLink {
            //                            context.send(viewAction: .developerOptions)
            //                        })
            //                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
            //            }
            
            //            signOutSection
            
            //            if context.viewState.showDeveloperOptions {
            //                developerOptionsSection
            //            }
        }
        .zeroList()
        .toolbar { toolbar }
    }
    
    private var userSection: some View {
        Section {
            ZeroListRow(kind: .custom {
                Button {
                    context.send(viewAction: .userDetails)
                } label: {
                    VStack(alignment: .center, spacing: 12) {
                        LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                            name: context.viewState.userDisplayName,
                                            contentID: context.viewState.userID,
                                            avatarSize: .user(on: .settings),
                                            mediaProvider: context.mediaProvider,
                                            onTap: { _ in
                            context.send(viewAction: .userDetails)
                        })
                        .accessibilityHidden(true)
                        
                        VStack {
                            Text(context.viewState.userDisplayName ?? "")
                                .font(.zero.headingSMSemibold)
                                .foregroundColor(.compound.textPrimary)
                            
                            if context.viewState.primaryZeroId != nil {
                                Text(context.viewState.primaryZeroId!)
                                    .font(.zero.bodyMD)
                                    .foregroundColor(.compound.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            })
        }
    }
    
    private var zeroMenuSection: some View {
        Section {
            ZeroListRow(kind: .custom({
                HorizontalDivider()
            }))
            
            /// User Rewards
            ZeroListRow(kind: .custom {
                Button {
                    context.send(viewAction: .rewards)
                } label: {
                    userRewardsView
                }
            })
            
            ZeroListRow(kind: .custom({
                HorizontalDivider()
            }))
            
            /// Refer A Friend
            ZeroListRow(label: .plain(title: "Refer a Friend"),
                        kind: .navigationLink {
                context.send(viewAction: .referAFriend)
            })
            .accessibilityIdentifier("settings-refer-friend")
            
            /// Notifications
            ZeroListRow(label: .plain(title: L10n.screenNotificationSettingsTitle),
                        kind: .navigationLink {
                context.send(viewAction: .notifications)
            })
            .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            
            /// Backup Key
            switch context.viewState.securitySectionMode {
            case .secureBackup:
                ZeroListRow(label: .plain(title: L10n.commonEncryption),
                            details: context.viewState.showSecuritySectionBadge ? .icon(securitySectionBadge) : nil,
                            kind: .navigationLink { context.send(viewAction: .secureBackup) })
                .accessibilityIdentifier(A11yIdentifiers.settingsScreen.secureBackup)
            default:
                EmptyView()
            }
            
            /// Advanced Settings
            ZeroListRow(label: .plain(title: "Advanced Settings"),
                        kind: .navigationLink {
                context.send(viewAction: .developerOptions)
            })
            .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
            
            /// Logout
            ZeroListRow(label: .plain(title: L10n.screenSignoutPreferenceItem,
                                      role: .destructive),
                        kind: .button {
                context.send(viewAction: .logout)
            })
            .accessibilityIdentifier(A11yIdentifiers.settingsScreen.logout)
            
            ZeroListRow(kind: .custom({
                HorizontalDivider()
            }))
        } footer: {
            versionSection
        }
    }
    
    private var userRewardsView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Rewards")
                    .font(.zero.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.vertical, 2)
                
                Text("$\(context.viewState.userRewards.getRefPriceFormatted())")
                    .font(.robotoMonoRegular(size: 24))
                    .foregroundColor(.compound.textPrimary)
                    .overlay(alignment: .topTrailing) {
                        if context.viewState.showNewUserRewardsIntimation {
                            ZStack(alignment: .center) {
                                Circle().stroke(Color.zero.bgAccentRest.opacity(0.5), lineWidth: 2)
                                    .frame(width: 16, height: 16)
                                Circle().stroke(Color.zero.bgAccentRest, lineWidth: 2)
                                    .frame(width: 12, height: 12)
                                    .padding(4)
                                Circle()
                                    .fill(Color.zero.bgAccentRest)
                                    .frame(width: 8, height: 8)
                                    .padding(4)
                            }
                            .transition(.opacity)
                            .offset(x: 24, y: -8)
                        }
                    }
                
                Text("\(context.viewState.userRewards.getZeroCreditsFormatted()) MEOW")
                    .font(.robotoMonoRegular(size: 14))
                    .foregroundColor(.compound.textSecondary)
            }
            
            Spacer()
            
            CompoundIcon(\.chevronRight)
                .foregroundColor(.compound.iconTertiaryAlpha)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(.horizontal, 16)
    }
    
    private var manageMyAppSection: some View {
        Section {
            ZeroListRow(label: .default(title: "Invite Friend",
                                        icon: \.plus),
                        kind: .navigationLink {
                            context.send(viewAction: .inviteFriend)
                        })
                        .accessibilityIdentifier("settings-invite-friend")
            
            ZeroListRow(label: .default(title: L10n.screenNotificationSettingsTitle,
                                        icon: \.notifications),
                        kind: .navigationLink {
                            context.send(viewAction: .notifications)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            
//            ZeroListRow(label: .default(title: L10n.commonScreenLock,
//                                    icon: \.lock),
//                    kind: .navigationLink {
//                        context.send(viewAction: .appLock)
//                    })
//                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.screenLock)
            
            switch context.viewState.securitySectionMode {
            case .secureBackup:
                ZeroListRow(label: .default(title: L10n.commonEncryption,
                                            icon: \.key),
                            details: context.viewState.showSecuritySectionBadge ? .icon(securitySectionBadge) : nil,
                            kind: .navigationLink { context.send(viewAction: .secureBackup) })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.secureBackup)
            default:
                EmptyView()
            }
            
            ZeroListRow(label: .default(title: "Advanced Settings",
                                        icon: \.code),
                        kind: .navigationLink {
                            context.send(viewAction: .developerOptions)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
        }
    }
    
    private var manageAccountSection: some View {
        Section {
            if let url = context.viewState.accountProfileURL {
                ZeroListRow(label: .default(title: L10n.actionManageAccount,
                                            icon: \.userProfile),
                            kind: .button {
                                context.send(viewAction: .manageAccount(url: url))
                            })
                            .accessibilityIdentifier(A11yIdentifiers.settingsScreen.account)
            }
            
            if let url = context.viewState.accountSessionsListURL {
                ZeroListRow(label: .default(title: L10n.actionManageDevices,
                                            icon: \.devices),
                            kind: .button {
                                context.send(viewAction: .manageAccount(url: url))
                            })
            }
            
            if context.viewState.showBlockedUsers {
                ZeroListRow(label: .default(title: L10n.commonBlockedUsers,
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
            ZeroListRow(label: .default(title: L10n.commonAbout,
                                        icon: \.info),
                        kind: .navigationLink {
                            context.send(viewAction: .about)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.about)
            
            if context.viewState.isBugReportServiceEnabled {
                ZeroListRow(label: .default(title: L10n.commonReportAProblem,
                                        icon: \.chatProblem),
                        kind: .navigationLink {
                            context.send(viewAction: .reportBug)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.reportBug)
            }
            
            if context.viewState.showAnalyticsSettings {
                ZeroListRow(label: .default(title: L10n.commonAnalytics,
                                        icon: \.chart),
                        kind: .navigationLink {
                            context.send(viewAction: .analytics)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            }
            
            ZeroListRow(label: .default(title: L10n.commonAdvancedSettings,
                                    icon: \.settings),
                    kind: .navigationLink {
                        context.send(viewAction: .advancedSettings)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.advancedSettings)
        }
    }
    
    private var signOutSection: some View {
        Section {
            ZeroListRow(label: .action(title: L10n.screenSignoutPreferenceItem,
                                       icon: \.signOut,
                                       role: .destructive),
                        kind: .button {
                            context.send(viewAction: .logout)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.logout)
            
//            if context.viewState.showAccountDeactivation {
//                ZeroListRow(label: .action(title: L10n.actionDeactivateAccount,
//                                       icon: \.warning,
//                                       role: .destructive),
//                        kind: .navigationLink {
//                            context.send(viewAction: .deactivateAccount)
//                        })
//            }
        } footer: {
//            if !context.viewState.showDeveloperOptions {
//                versionSection
//            }
            versionSection
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
            Image(asset: Asset.Images.zeroLogoMark)
                .padding(.vertical, 8)
            
            versionText
                .frame(maxWidth: .infinity)
            
//            if let deviceID = context.viewState.deviceID {
//                Text(deviceID)
//            }
        }
        .compoundListSectionFooter()
        .textSelection(.enabled)
//        .onTapGesture(count: 7) {
//            context.send(viewAction: .enableDeveloperOptions)
//        }
    }
    
    private var versionText: Text {
        Text(L10n.settingsVersionNumber(InfoPlistReader.main.bundleShortVersionString, InfoPlistReader.main.bundleVersion))
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                context.send(viewAction: .close)
            } label: {
                CompoundIcon(\.close)
            }
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
