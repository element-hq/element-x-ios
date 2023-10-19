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
import SFSafeSymbols
import SwiftUI

struct SettingsScreen: View {
    @State private var showingLogoutConfirmation = false
    
    @ObservedObject var context: SettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            userSection
            
            accountSecuritySection
            
            mainSection
            
            if context.viewState.accountSessionsListURL != nil {
                manageSessionsSection
            }
            
            advancedOptionsSection
            
            signOutSection
        }
        .compoundList()
        .navigationTitle(L10n.commonSettings)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
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
                        
                        Spacer()
                        
                        CompoundIcon(\.chevronRight)
                            .foregroundColor(.compound.iconTertiaryAlpha)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                    .padding(.horizontal, ListRowPadding.horizontal)
                    .padding(.vertical, 8)
                }
            })
        }
    }
    
    @ViewBuilder
    private var accountSecuritySection: some View {
        if !context.viewState.isSessionVerified || context.viewState.chatBackupEnabled {
            Section {
                if !context.viewState.isSessionVerified {
                    ListRow(label: .default(title: L10n.actionCompleteVerification,
                                            systemIcon: .checkmarkShield),
                            kind: .button { context.send(viewAction: .sessionVerification) })
                } else if context.viewState.chatBackupEnabled {
                    ListRow(label: .default(title: L10n.commonChatBackup,
                                            icon: Image(asset: Asset.Images.secureBackupIcon)),
                            details: context.viewState.showSecureBackupBadge ? .icon(secureBackupBadge) : nil,
                            kind: .navigationLink { context.send(viewAction: .secureBackup) })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.secureBackup)
                }
            }
        }
    }
    
    private var mainSection: some View {
        Section {
            if context.viewState.accountProfileURL != nil {
                ListRow(label: .default(title: L10n.actionManageAccount, systemIcon: .person),
                        kind: .button {
                            context.send(viewAction: .accountProfile)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.account)
            }
            
            ListRow(label: .default(title: L10n.screenNotificationSettingsTitle,
                                    systemIcon: .bell),
                    kind: .navigationLink {
                        context.send(viewAction: .notifications)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.notifications)
            
            ListRow(label: .default(title: L10n.commonAnalytics,
                                    systemIcon: .chartBar),
                    kind: .navigationLink {
                        context.send(viewAction: .analytics)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            
            if context.viewState.showAppLockSettings {
                ListRow(label: .default(title: UntranslatedL10n.commonScreenLock,
                                        systemIcon: .lock),
                        kind: .navigationLink {
                            context.send(viewAction: .appLock)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.analytics)
            }
            
            ListRow(label: .default(title: L10n.commonReportABug,
                                    systemIcon: .ladybug),
                    kind: .navigationLink {
                        context.send(viewAction: .reportBug)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.reportBug)
            
            ListRow(label: .default(title: L10n.commonAbout,
                                    systemIcon: .questionmarkCircle),
                    kind: .navigationLink {
                        context.send(viewAction: .about)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.about)
        }
    }
    
    private var manageSessionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.actionManageDevices, systemIcon: deviceIcon),
                    kind: .button {
                        context.send(viewAction: .accountSessionsList)
                    })
        }
    }
    
    private var deviceIcon: SFSymbol {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return .macbookAndIphone
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .ipad
        } else {
            return .iphone
        }
    }
    
    private var advancedOptionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonAdvancedSettings,
                                    systemIcon: .gearshape2),
                    kind: .navigationLink {
                        context.send(viewAction: .advancedSettings)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.settingsScreen.advancedSettings)
            
            if context.viewState.showDeveloperOptions {
                ListRow(label: .default(title: L10n.commonDeveloperOptions,
                                        systemIcon: .hammerCircle),
                        kind: .navigationLink {
                            context.send(viewAction: .developerOptions)
                        })
                        .accessibilityIdentifier(A11yIdentifiers.settingsScreen.developerOptions)
            }
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
                        Button(L10n.screenSignoutConfirmationDialogSubmit, role: .destructive) {
                            context.send(viewAction: .logout)
                        }
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
    private var secureBackupBadge: some View {
        if context.viewState.showSecureBackupBadge {
            BadgeView(size: 10)
        }
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

struct SettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let verificationController = SessionVerificationControllerProxyMock()
        verificationController.isVerified = false
        let userSession = MockUserSession(sessionVerificationController: verificationController,
                                          clientProxy: MockClientProxy(userID: "@userid:example.com",
                                                                       deviceID: "AAAAAAAAAAA"),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        return SettingsScreenViewModel(userSession: userSession,
                                       appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        NavigationStack {
            SettingsScreen(context: viewModel.context)
        }
    }
}
