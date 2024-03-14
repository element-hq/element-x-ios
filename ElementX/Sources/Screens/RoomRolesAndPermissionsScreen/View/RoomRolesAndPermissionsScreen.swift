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

struct RoomRolesAndPermissionsScreen: View {
    @ObservedObject var context: RoomRolesAndPermissionsScreenViewModel.Context
    
    var body: some View {
        Form {
            rolesSection
            permissionsSection
            
            resetSection
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomRolesAndPermissionsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    private var rolesSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsAdmins,
                                    icon: \.admin),
                    details: administratorDetails,
                    kind: .navigationLink {
                        context.send(viewAction: .editRoles(.administrators))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.administrators)
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsModerators,
                                    icon: \.chatProblem),
                    details: moderatorDetails,
                    kind: .navigationLink {
                        context.send(viewAction: .editRoles(.moderators))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.moderators)
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsChangeMyRole,
                                    icon: \.edit),
                    kind: .button {
                        context.send(viewAction: .editOwnUserRole)
                    })
        } header: {
            Text(L10n.screenRoomRolesAndPermissionsRolesHeader)
                .compoundListSectionHeader()
        }
    }
    
    private var administratorDetails: ListRowDetails<Image> {
        if let administratorCount = context.viewState.administratorCount {
            .title("\(administratorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    private var moderatorDetails: ListRowDetails<Image> {
        if let moderatorCount = context.viewState.moderatorCount {
            .title("\(moderatorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    private var permissionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsRoomDetails,
                                    icon: \.info),
                    details: .isWaiting(context.viewState.permissions == nil),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.roomDetails))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.roomDetails)
                    .disabled(context.viewState.permissions == nil)
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsMessagesAndContent,
                                    icon: \.chat),
                    details: .isWaiting(context.viewState.permissions == nil),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.messagesAndContent))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.messagesAndContent)
                    .disabled(context.viewState.permissions == nil)
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsMemberModeration,
                                    icon: \.user),
                    details: .isWaiting(context.viewState.permissions == nil),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.memberModeration))
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomRolesAndPermissionsScreen.memberModeration)
                    .disabled(context.viewState.permissions == nil)
        } header: {
            Text(L10n.screenRoomRolesAndPermissionsPermissionsHeader)
                .compoundListSectionHeader()
        }
    }
    
    private var resetSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenRoomRolesAndPermissionsReset,
                                  role: .destructive),
                    kind: .button {
                        context.send(viewAction: .reset)
                    })
        }
    }
}

// MARK: - Previews

struct RoomRolesAndPermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomRolesAndPermissionsScreenViewModel(initialPermissions: RoomPermissions(powerLevels: .mock),
                                                                  roomProxy: RoomProxyMock(with: .init(members: .allMembersAsAdmin)),
                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                  analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        NavigationStack {
            RoomRolesAndPermissionsScreen(context: viewModel.context)
        }
    }
}
