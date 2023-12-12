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

import Compound
import SwiftUI

struct HomeScreenUserMenuButton: View {
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
                        if context.viewState.showSettingsMenuOptionBadge {
                            CompoundIcon(asset: Asset.Images.settingsIconWithBadge)
                        } else {
                            CompoundIcon(\.settings)
                        }
                    }
                }
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.settings)
            }
            Section {
                MatrixUserShareLink(userID: context.viewState.userID) {
                    Label(L10n.actionInvite, iconAsset: Asset.Images.shareIos)
                }
                Button {
                    context.send(viewAction: .userMenu(action: .feedback))
                } label: {
                    Label(L10n.commonReportAProblem, icon: \.chatProblem)
                }
            }
            Section {
                Button(role: .destructive) {
                    context.send(viewAction: .userMenu(action: .logout))
                } label: {
                    Label(L10n.screenSignoutPreferenceItem, iconAsset: Asset.Images.signOut)
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
        .accessibilityLabel(L10n.a11yUserMenu)
    }
}
