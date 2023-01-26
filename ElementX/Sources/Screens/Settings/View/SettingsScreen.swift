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
            
            simplifiedSection
                .listRowBackground(rowBackgroundColor)

//            analyticsSection
//                .listRowBackground(rowBackgroundColor)

//            userInterfaceSection
//                .listRowBackground(rowBackgroundColor)

//            logoutSection
//                .listRowBackground(rowBackgroundColor)
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
                        .font(.title3)
                        .foregroundColor(.element.primaryContent)
                    Text(context.viewState.userID)
                        .font(.subheadline)
                        .foregroundColor(.element.primaryContent)
                }
            }
            .listRowInsets(listRowInsets)
        }
    }
    
    private var simplifiedSection: some View {
        Section {
            SettingsDefaultRow(title: ElementL10n.sendBugReport,
                               image: Image(systemName: "questionmark.circle")) {
                context.send(viewAction: .reportBug)
            }
            .accessibilityIdentifier("reportBugButton")
            
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
        }
    }

    @ViewBuilder
    private var userInterfaceSection: some View {
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
            VStack {
                versionText
                    .frame(maxWidth: .infinity)
                
                if let deviceId = context.viewState.deviceID {
                    Text(deviceId)
                }
            }
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
