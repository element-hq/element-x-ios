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
    }
    
    var rolesSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsAdmins,
                                    icon: \.admin),
                    details: administratorDetails,
                    kind: .navigationLink {
                        context.send(viewAction: .editRoles(.administrators))
                    })
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsModerators,
                                    icon: \.chatProblem),
                    details: moderatorDetails,
                    kind: .navigationLink {
                        context.send(viewAction: .editRoles(.moderators))
                    })
        } header: {
            Text(L10n.screenRoomRolesAndPermissionsRolesHeader)
                .compoundListSectionHeader()
        }
    }
    
    var administratorDetails: ListRowDetails<Image> {
        if let administratorCount = context.viewState.administratorCount {
            .title("\(administratorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    var moderatorDetails: ListRowDetails<Image> {
        if let moderatorCount = context.viewState.moderatorCount {
            .title("\(moderatorCount)")
        } else {
            .isWaiting(true)
        }
    }
    
    var permissionsSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsRoomDetails,
                                    icon: \.info),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.roomDetails))
                    })
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsMessagesAndContent,
                                    icon: \.chat),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.messagesAndContent))
                    })
            
            ListRow(label: .default(title: L10n.screenRoomRolesAndPermissionsMemberModeration,
                                    icon: \.user),
                    kind: .navigationLink {
                        context.send(viewAction: .editPermissions(.memberModeration))
                    })
        } header: {
            Text(L10n.screenRoomRolesAndPermissionsPermissionsHeader)
                .compoundListSectionHeader()
        }
    }
    
    var resetSection: some View {
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
    static let viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: RoomProxyMock(with: .init(members: .allMembersAsAdmin)))
    static var previews: some View {
        NavigationStack {
            RoomRolesAndPermissionsScreen(context: viewModel.context)
        }
    }
}
