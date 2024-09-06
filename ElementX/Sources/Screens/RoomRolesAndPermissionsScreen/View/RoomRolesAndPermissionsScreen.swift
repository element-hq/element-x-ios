//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                                                                  roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)),
                                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                                  analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        NavigationStack {
            RoomRolesAndPermissionsScreen(context: viewModel.context)
        }
    }
}
