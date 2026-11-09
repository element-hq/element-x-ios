//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SFSafeSymbols
import SwiftUI

struct SettingsScreen: View {
    @Bindable var context: SettingsScreenViewModel.Context
    
    private let stackedOtherAccountsLimit = 3
    
    var body: some View {
        Form {
            userSection
            
            if context.viewState.showSwitchAccountsSection {
                switchAccountsSection
            }
            
            accountSettingsSection
            
            signOutSection
            
            appSettingsSection
        }
        .compoundList()
        .navigationTitle(L10n.commonSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(context.viewState.navigationBarVisibility, for: .navigationBar)
        .toolbar { toolbar }
        .sheet(isPresented: $context.isPresentingStatusPicker) {
            SettingsScreenUserStatusPickerView { action in
                context.send(viewAction: .userStatus(action))
            }
            .presentationDetents([.medium])
            .presentationBackground(.compound.bgCanvasDefault)
        }
    }
    
    private var userSection: some View {
        Section {
            ListRow(kind: .custom {
                Button {
                    context.send(viewAction: .userDetails)
                } label: {
                    HStack(spacing: 12) {
                        LoadableAvatarImage(url: context.viewState.userProfile.avatarURL,
                                            name: context.viewState.userProfile.displayName,
                                            contentID: context.viewState.userProfile.id,
                                            avatarSize: .user(on: .settings),
                                            mediaProvider: context.mediaProvider)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.viewState.userProfile.displayName ?? "")
                                .font(.compound.headingMD)
                                .foregroundColor(.compound.textPrimary)
                            
                            Text(context.viewState.userProfile.id)
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
            
            if context.viewState.showUserStatusInput {
                SettingsScreenUserStatusRow(mode: context.viewState.userStatusRowMode) { action in
                    context.send(viewAction: .userStatus(action))
                }
            }
        }
    }
    
    private var switchAccountsSection: some View {
        Section {
            if context.viewState.otherAccounts.isEmpty {
                addAccountRow
            } else {
                switchAccountsHeader
                
                if context.isOtherAccountsSectionExpanded {
                    ForEach(context.viewState.otherAccounts, id: \.userID) { account in
                        otherAccountRow(account)
                    }
                    
                    addAccountRow
                }
            }
        }
    }
    
    private var switchAccountsHeader: some View {
        ListRow(label: .plain(title: L10n.commonSwitchAccounts),
                details: .icon(switchAccountsHeaderAccessories),
                kind: .button {
                    withAnimation {
                        context.isOtherAccountsSectionExpanded.toggle()
                    }
                })
                .accessibilityValue(context.isOtherAccountsSectionExpanded ? L10n.a11yStateExpanded : L10n.a11yStateCollapsed)
    }
    
    private var switchAccountsHeaderAccessories: some View {
        HStack(spacing: 16) {
            if !context.isOtherAccountsSectionExpanded {
                HStack(spacing: 4) {
                    StackedAvatarsView(overlap: 8,
                                       lineWidth: 2,
                                       shouldStackFromLast: true,
                                       avatars: context.viewState.otherAccounts.prefix(stackedOtherAccountsLimit).map { account in
                                           .init(url: account.userProfile.avatarURL,
                                                 name: account.userProfile.displayName,
                                                 contentID: account.userID,
                                                 mediaProvider: account.mediaProvider)
                                       },
                                       avatarSize: .user(on: .settingsOtherAccountsStack),
                                       mediaProvider: context.mediaProvider)
                    
                    if context.viewState.otherAccounts.count > stackedOtherAccountsLimit {
                        Text("+\(context.viewState.otherAccounts.count - stackedOtherAccountsLimit)")
                            .font(.compound.bodySM)
                            .foregroundStyle(.compound.textPrimary)
                    }
                }
            }
            
            CompoundIcon(\.chevronDown, size: .small, relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconPrimary)
                .padding(2)
                .background(.compound.bgCanvasDefault, in: .circle)
                .overlay {
                    Circle()
                        .strokeBorder(.compound.borderInteractiveSecondary, lineWidth: 1)
                }
                .rotationEffect(.degrees(context.isOtherAccountsSectionExpanded ? 180 : 0))
        }
        .accessibilityHidden(true)
    }
    
    private var addAccountRow: some View {
        ListRow(label: .default(title: L10n.commonAddAnotherAccount,
                                icon: \.plus),
                kind: .navigationLink {
                    context.send(viewAction: .addAccount)
                })
                .accessibilityIdentifier(A11yIdentifiers.settingsScreen.addAccount)
    }
    
    private func otherAccountRow(_ account: UserSessionDetails) -> some View {
        let profile = account.userProfile
        var title = profile.displayName ?? profile.id
        if let emoji = profile.status.displayed?.emoji {
            title += " \(emoji)"
        }
        
        return ListRow(label: .avatar(title: title,
                                      description: profile.displayName != nil ? profile.id : nil,
                                      icon: LoadableAvatarImage(url: profile.avatarURL,
                                                                name: profile.displayName,
                                                                contentID: profile.id,
                                                                avatarSize: .user(on: .settingsOtherAccount),
                                                                mediaProvider: account.mediaProvider)),
                       details: account.unreadCount > 0 ? .icon(NotificationCountBadge(count: account.unreadCount)) : nil,
                       kind: .button {
                           context.send(viewAction: .switchAccount(userID: account.userID))
                       })
    }
    
    private var accountSettingsSection: some View {
        Section {
            if let url = context.viewState.accountProfileURL {
                ListRow(label: .default(title: L10n.actionManageAccountAndDevices,
                                        icon: \.userProfile),
                        kind: .button {
                            context.send(viewAction: .manageAccount(url: url))
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.account)
            }
            
            if context.viewState.showLinkNewDeviceButton {
                ListRow(label: .default(title: L10n.commonLinkNewDevice,
                                        icon: \.devices),
                        kind: .navigationLink {
                            context.send(viewAction: .linkNewDevice)
                        })
            }
            
            ListRow(label: .default(title: L10n.screenNotificationSettingsTitle,
                                    icon: \.notifications),
                    kind: .navigationLink {
                        context.send(viewAction: .notifications)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            
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
            
            ListRow(label: .default(title: L10n.commonModerationAndSafety,
                                    icon: \.admin),
                    kind: .navigationLink {
                        context.send(viewAction: .moderationAndSafety)
                    })
            
            if context.viewState.isBugReportServiceEnabled {
                ListRow(label: .default(title: L10n.commonReportAProblem,
                                        icon: \.chatProblem),
                        kind: .navigationLink {
                            context.send(viewAction: .reportBug)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.reportBug)
            }
        } header: {
            Text(L10n.commonAccountSettings)
                .compoundListSectionHeader()
        }
    }
    
    private var signOutSection: some View {
        Section {
            ListRow(label: .action(title: L10n.screenSignoutPreferenceItem,
                                   icon: \.close,
                                   role: .destructive),
                    kind: .button {
                        context.send(viewAction: .logout)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.logout)
            
            if context.viewState.showAccountDeactivation {
                ListRow(label: .action(title: L10n.actionDeleteAccount,
                                       icon: \.delete,
                                       role: .destructive),
                        kind: .navigationLink {
                            context.send(viewAction: .deactivateAccount)
                        })
            }
        }
    }
    
    private var appSettingsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonAppearance,
                                    icon: \.darkMode),
                    kind: .picker(selection: $context.appAppearance,
                                  items: AppAppearance.allCases.map { (title: $0.name, tag: $0) }))
            
            ListRow(label: .default(title: L10n.commonMediaUploadQuality,
                                    icon: \.image),
                    kind: .navigationLink {
                        context.send(viewAction: .mediaUploadQuality)
                    })
            
            ListRow(label: .default(title: L10n.commonScreenLock,
                                    icon: \.lock),
                    kind: .navigationLink {
                        context.send(viewAction: .appLock)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.screenLock)
            
            ListRow(label: .default(title: L10n.commonLocationSharing,
                                    icon: \.locationPin),
                    kind: .navigationLink {
                        context.send(viewAction: .locationSharing)
                    })
            
            if context.viewState.showAnalyticsSettings {
                ListRow(label: .default(title: L10n.commonAnalytics,
                                        icon: \.chart),
                        kind: .navigationLink {
                            context.send(viewAction: .analytics)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            }
            
            ListRow(label: .default(title: L10n.screenAdvancedSettingsLabs,
                                    icon: \.labs),
                    kind: .navigationLink {
                        context.send(viewAction: .labs)
                    })
            
            ListRow(label: .default(title: L10n.commonAbout,
                                    icon: \.info),
                    kind: .navigationLink {
                        context.send(viewAction: .about)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.about)
            
            if context.viewState.showDeveloperOptions {
                ListRow(label: .default(title: L10n.commonDeveloperOptions,
                                        icon: \.code),
                        kind: .navigationLink {
                            context.send(viewAction: .developerOptions)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
            }
        } header: {
            Text(L10n.commonAppSettings)
                .compoundListSectionHeader()
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
        // Let's not snapshot a changing version string.
        let shortVersion = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        let version = ProcessInfo.isRunningTests ? "1" : InfoPlistReader.main.bundleVersion
        return Text(L10n.settingsVersionNumber(shortVersion, version))
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .close) { context.send(viewAction: .close) }
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

private extension AppAppearance {
    var name: String {
        switch self {
        case .system:
            L10n.themeSystem
        case .light:
            L10n.themeLight
        case .dark:
            L10n.themeDark
        }
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
struct SettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let bugReportDisabledViewModel = makeViewModel(isBugReportServiceEnabled: false)
    static let twoAccountsViewModel = makeViewModel(otherAccounts: [bob(unreadCount: 3)])
    static let twoAccountsCollapsedViewModel = makeViewModel(otherAccounts: [bob(unreadCount: 3)],
                                                             isOtherAccountsSectionExpanded: false)
    static let threeAccountsViewModel = makeViewModel(otherAccounts: [bob(unreadCount: 5, status: .mockHoliday),
                                                                      account(userID: "@charlie:element.io")])
    static let fiveAccountsCollapsedViewModel = makeViewModel(otherAccounts: [bob(unreadCount: 5, status: .mockHoliday),
                                                                              account(userID: "@charlie:element.io"),
                                                                              account(userID: "@dan:matrix.org", displayName: "Dan"),
                                                                              account(userID: "@eve:example.com", displayName: "Eve")],
                                                              isOtherAccountsSectionExpanded: false)
    
    static var previews: some View {
        ElementNavigationStack {
            SettingsScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1300)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default")
        
        ElementNavigationStack {
            SettingsScreen(context: bugReportDisabledViewModel.context)
        }
        .snapshotPreferences(expect: bugReportDisabledViewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1250)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Bug report disabled")
        
        ElementNavigationStack {
            SettingsScreen(context: twoAccountsViewModel.context)
        }
        .snapshotPreferences(expect: twoAccountsViewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1400)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Two accounts")
        
        ElementNavigationStack {
            SettingsScreen(context: twoAccountsCollapsedViewModel.context)
        }
        .snapshotPreferences(expect: twoAccountsCollapsedViewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1300)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Two accounts collapsed")
        
        ElementNavigationStack {
            SettingsScreen(context: threeAccountsViewModel.context)
        }
        .snapshotPreferences(expect: threeAccountsViewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1450)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Three accounts")
        
        ElementNavigationStack {
            SettingsScreen(context: fiveAccountsCollapsedViewModel.context)
        }
        .snapshotPreferences(expect: fiveAccountsCollapsedViewModel.context.observe(\.viewState.accountProfileURL).map { $0 != nil })
        .frame(height: 1300)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Five accounts collapsed")
    }
    
    static func makeViewModel(isBugReportServiceEnabled: Bool = true,
                              otherAccounts: [UserSessionDetails] = [],
                              isOtherAccountsSectionExpanded: Bool = true) -> SettingsScreenViewModel {
        let userSettings = UserSettings.mock()
        userSettings.app.multiAccountEnabled = true
        userSettings.app.linkNewDeviceEnabled = true
        userSettings.app.isOtherAccountsSectionExpanded = isOtherAccountsSectionExpanded
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@alice:example.com",
                                                                                   deviceID: "AAAAAAAAAAA",
                                                                                   displayName: "Alice Liddell",
                                                                                   status: .mockFocussing)),
                                                userSettings: userSettings))
        return SettingsScreenViewModel(userSession: userSession,
                                       availableSessionsPublisher: .init([.init(userSession: userSession)] + otherAccounts),
                                       isBugReportServiceEnabled: isBugReportServiceEnabled,
                                       isInSecondaryWindow: false,
                                       userIndicatorController: UserIndicatorControllerMock())
    }
    
    static func bob(unreadCount: Int, status: UserStatus = .init()) -> UserSessionDetails {
        account(userID: "@bob:matrix.org", displayName: "Bob", unreadCount: unreadCount, status: status)
    }
    
    static func account(userID: String, displayName: String? = nil, unreadCount: Int = 0, status: UserStatus = .init()) -> UserSessionDetails {
        UserSessionDetails(userProfile: UserProfile(userID: userID, displayName: displayName, status: status),
                           unreadCount: unreadCount,
                           mediaProvider: MediaProviderMock(.init()))
    }
}
