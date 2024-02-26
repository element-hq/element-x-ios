//
// Copyright 2024 New Vector Ltd
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

struct RoomMembersListManageMemberSheet: View {
    let member: RoomMemberDetails
    let context: RoomMembersListScreenViewModel.Context
    
    @State private var isPresentingRemoveConfirmation = false
    
    var body: some View {
        Form {
            AvatarHeaderView(member: member,
                             avatarSize: .user(on: .memberDetails),
                             imageProvider: context.imageProvider) {
                EmptyView()
            }
            
            Section {
                ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberUserInfo,
                                        icon: \.info),
                        kind: .button {
                            context.send(viewAction: .showMemberDetails(member))
                        })
                
                if !member.isBanned {
                    ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberRemove,
                                            icon: \.block,
                                            role: .destructive),
                            kind: .button {
                                isPresentingRemoveConfirmation = true
                            })
                } else {
                    // Theoretically we shouldn't reach this branch but just in case we do.
                    ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberUnbanAction,
                                            icon: \.block,
                                            role: .destructive),
                            kind: .button {
                                context.send(viewAction: .unbanMember(member))
                            })
                }
            }
        }
        .compoundList()
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large, .fraction(0.5)]) // TODO: Use the ideal height somehow?
        .confirmationDialog(L10n.screenRoomMemberListManageMemberRemoveConfirmationTitle,
                            isPresented: $isPresentingRemoveConfirmation,
                            titleVisibility: .visible) {
            if context.viewState.canKickUsers {
                Button(L10n.screenRoomMemberListManageMemberRemoveConfirmationKick) {
                    context.send(viewAction: .kickMember(member))
                }
            }
            if context.viewState.canBanUsers {
                Button(L10n.screenRoomMemberListManageMemberRemoveConfirmationBan, role: .destructive) {
                    context.send(viewAction: .banMember(member))
                }
            }
        }
    }
}

struct RoomMembersListManageMemberSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomMembersListScreenViewModel.mock
    
    static var previews: some View {
        RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockDan),
                                         context: viewModel.context)
            .previewDisplayName("Joined")
        
        RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockBanned[3]),
                                         context: viewModel.context)
            .previewDisplayName("Banned")
    }
}

struct RoomMembersListManageMemberSheetLive_Previews: PreviewProvider {
    static let viewModel = RoomMembersListScreenViewModel.mock
    
    static var previews: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockDan),
                                                 context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}

private extension RoomMembersListScreenViewModel {
    static var mock: RoomMembersListScreenViewModel {
        RoomMembersListScreenViewModel(initialMode: .members,
                                       roomProxy: RoomProxyMock(with: .init()),
                                       mediaProvider: MockMediaProvider(),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                       appSettings: ServiceLocator.shared.settings)
    }
}
