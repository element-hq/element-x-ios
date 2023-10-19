//
// Copyright 2023 New Vector Ltd
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

struct HomeScreenUserMenuButton: View {
    @State private var showingLogoutConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    var body: some View {
        Menu {
            Section {
                Button {
                    context.send(viewAction: .userMenu(action: .settings))
                } label: {
                    Label {
                        Text(L10n.commonSettings)
                    } icon: {
                        settingsIconImage
                    }
                }
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.settings)
            }
            Section {
                MatrixUserShareLink(userID: context.viewState.userID) {
                    Label(L10n.actionInvite, systemImage: "square.and.arrow.up")
                }
                Button {
                    context.send(viewAction: .userMenu(action: .feedback))
                } label: {
                    Label(L10n.commonReportABug, systemImage: "ladybug")
                }
            }
            Section {
                Button(role: .destructive) {
                    showingLogoutConfirmation = true
                } label: {
                    Label(L10n.screenSignoutPreferenceItem, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                name: context.viewState.userDisplayName,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .home),
                                imageProvider: context.imageProvider)
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                .overlayBadge(10, isBadged: context.viewState.showUserMenuBadge)
                .compositingGroup()
        }
        .alert(L10n.screenSignoutConfirmationDialogTitle,
               isPresented: $showingLogoutConfirmation) {
            Button(L10n.screenSignoutConfirmationDialogSubmit,
                   role: .destructive) {
                context.send(viewAction: .userMenu(action: .signOut))
            }
        } message: {
            Text(L10n.screenSignoutConfirmationDialogContent)
        }
        .accessibilityLabel(L10n.a11yUserMenu)
    }
    
    // MARK: - Private
        
    /// Menu doesn't render composed views. Trick it into showing a badge.
    private var settingsIconImage: Image? {
        let settingsIcon = Image(systemSymbol: .gearshape)
            .resizable()
            .frame(width: 100, height: 100)
            .overlayBadge(40, isBadged: context.viewState.showSettingsMenuOptionBadge)
            .colorScheme(colorScheme)
            .padding()
        
        let renderer = ImageRenderer(content: settingsIcon)
        
        guard let image = renderer.uiImage else {
            return nil
        }
        
        return Image(uiImage: image)
    }
}
