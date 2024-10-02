//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMembersListManageMemberSheet: View {
    let member: RoomMemberDetails
    let actions: [RoomMembersListScreenManagementDetails.Action]
    
    @ObservedObject var context: RoomMembersListScreenViewModel.Context
    
    @State private var isPresentingBanConfirmation = false
    
    var body: some View {
        Form {
            AvatarHeaderView(member: member,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) {
                EmptyView()
            }
            
            Section {
                ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberUserInfo,
                                        icon: \.userProfileSolid),
                        kind: .button {
                            context.send(viewAction: .showMemberDetails(member))
                        })
                
                if actions.contains(.kick) {
                    ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberRemove,
                                            icon: \.close),
                            kind: .button {
                                context.send(viewAction: .kickMember(member))
                            })
                }
                
                if actions.contains(.ban) {
                    ListRow(label: .default(title: L10n.screenRoomMemberListManageMemberBan,
                                            icon: \.block,
                                            role: .destructive),
                            kind: .button {
                                isPresentingBanConfirmation = true
                            })
                }
            }
        }
        .compoundList()
        .scrollBounceBehavior(.basedOnSize)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large, .fraction(0.54)]) // Maybe find a way to use the ideal height somehow?
        .alert(L10n.screenRoomMemberListBanMemberConfirmationTitle, isPresented: $isPresentingBanConfirmation) {
            Button(L10n.actionCancel, role: .cancel) { }
            Button(L10n.screenRoomMemberListBanMemberConfirmationAction) {
                context.send(viewAction: .banMember(member))
            }
        } message: {
            Text(L10n.screenRoomMemberListBanMemberConfirmationDescription)
        }
    }
}

struct RoomMembersListManageMemberSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomMembersListScreenViewModel.mock
    
    static var previews: some View {
        RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockDan),
                                         actions: [.kick, .ban],
                                         context: viewModel.context)
            .previewDisplayName("Joined")
            .snapshotPreferences(delay: 0.2)
        
        RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockBanned[3]),
                                         actions: [],
                                         context: viewModel.context)
            .previewDisplayName("Banned")
            .snapshotPreferences(delay: 0.2)
    }
}

struct RoomMembersListManageMemberSheetLive_Previews: PreviewProvider {
    static let viewModel = RoomMembersListScreenViewModel.mock
    
    static var previews: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                RoomMembersListManageMemberSheet(member: .init(withProxy: RoomMemberProxyMock.mockDan),
                                                 actions: [.kick, .ban],
                                                 context: viewModel.context)
            }
            .previewDisplayName("Sheet")
    }
}

private extension RoomMembersListScreenViewModel {
    static var mock: RoomMembersListScreenViewModel {
        RoomMembersListScreenViewModel(initialMode: .members,
                                       roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsAdmin)),
                                       mediaProvider: MockMediaProvider(),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                       analytics: ServiceLocator.shared.analytics)
    }
}
