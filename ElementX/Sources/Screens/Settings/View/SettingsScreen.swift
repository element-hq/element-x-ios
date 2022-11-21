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
    // MARK: Private

    @State private var showingLogoutConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = ElementSettings.shared

    @ScaledMetric private var avatarSize = AvatarSize.user(on: .settings).value
    @ScaledMetric private var menuIconSize = 30.0
    private let listRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    
    // MARK: Public
    
    @ObservedObject var context: SettingsViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        Form {
            userSection
                .listRowBackground(rowBackgroundColor)

            appearanceSection
                .listRowBackground(rowBackgroundColor)

            analyticsSection
                .listRowBackground(rowBackgroundColor)

            userInterfaceSection
                .listRowBackground(rowBackgroundColor)

            logoutSection
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
        .element.systemGray6
    }

    private var rowBackgroundColor: Color {
        colorScheme == .light ? .element.background : .element.system
    }

    private var userSection: some View {
        Section {
            HStack(spacing: 13) {
                userAvatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.viewState.userDisplayName ?? "")
                        .font(.title3)
                    Text(context.viewState.userID)
                        .font(.subheadline)
                }
            }
            .listRowInsets(listRowInsets)
        }
    }

    private var appearanceSection: some View {
        Section {
            Button(action: appearance) {
                HStack {
                    Image(systemName: "paintpalette")
                        .foregroundColor(.element.systemGray)
                        .padding(4)
                        .background(Color.element.systemGray6)
                        .clipShape(Circle())
                        .frame(width: menuIconSize, height: menuIconSize)
                    Text(ElementL10n.settingsAppearance)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .listRowInsets(listRowInsets)
            .foregroundColor(.element.primaryContent)
            .accessibilityIdentifier("appearanceButton")
        }
    }

    @ViewBuilder
    private var userAvatar: some View {
        if let avatar = context.viewState.userAvatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        } else {
            PlaceholderAvatarImage(text: context.viewState.userDisplayName ?? context.viewState.userID, contentId: context.viewState.userID)
                .clipShape(Circle())
                .frame(width: avatarSize, height: avatarSize)
        }
    }
    
    private var analyticsSection: some View {
        Section {
            Button { context.send(viewAction: .reportBug) } label: {
                HStack {
                    Text(ElementL10n.sendBugReport)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .listRowInsets(listRowInsets)
            .listRowSeparator(.hidden)
            .foregroundColor(.element.primaryContent)
            .accessibilityIdentifier("reportBugButton")

            if BuildSettings.settingsCrashButtonVisible {
                Button("Crash app",
                       role: .destructive) { context.send(viewAction: .crash)
                }
                .listRowInsets(listRowInsets)
                .accessibilityIdentifier("crashButton")
            }
        }
    }

    @ViewBuilder
    private var userInterfaceSection: some View {
        if BuildSettings.settingsShowTimelineStyle {
            Section {
                Picker(ElementL10n.settingsTimelineStyle, selection: $settings.timelineStyle) {
                    ForEach(TimelineStyle.allCases, id: \.self) { style in
                        Text(style.description)
                            .tag(style)
                    }
                }
                .listRowInsets(listRowInsets)
                .accessibilityIdentifier("timelineStylePicker")
            }
        }
    }
    
    private var logoutSection: some View {
        Section {
            Button { showingLogoutConfirmation = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.element.systemGray)
                        .padding(4)
                        .background(Color.element.systemGray6)
                        .clipShape(Circle())
                        .frame(width: menuIconSize, height: menuIconSize)
                    Text(ElementL10n.actionSignOut)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundColor(.element.tertiaryContent)
                }
            }
            .listRowInsets(listRowInsets)
            .foregroundColor(.element.primaryContent)
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
            versionText
                .frame(maxWidth: .infinity)
        }
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.title3.bold())
                .foregroundColor(.element.secondaryContent)
                .padding(4)
        }
        .accessibilityIdentifier("closeButton")
    }

    private func appearance() {
        #warning("Not implemented")
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

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let viewModel = SettingsViewModel(withUserSession: userSession)
        
        NavigationView {
            SettingsScreen(context: viewModel.context)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
