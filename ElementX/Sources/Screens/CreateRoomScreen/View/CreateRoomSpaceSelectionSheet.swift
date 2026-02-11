//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CreateRoomSpaceSelectionSheet: View {
    @ObservedObject var context: CreateRoomScreenViewModel.Context
    @Environment(\.dismiss) private var dismiss
    
    private var dragIndicatorVisibilty: Visibility {
        if #available(iOS 26, *) {
            .hidden
        } else {
            .automatic
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ListRow(label: .plain(title: L10n.screenCreateRoomSpaceSelectionNoSpaceOption),
                            kind: .selection(isSelected: context.selectedSpace == nil) {
                                context.selectedSpace = nil
                                dismiss()
                            })
                    ForEach(context.viewState.editableSpaces, id: \.id) { space in
                        ListRow(label: .avatar(title: space.name,
                                               description: space.canonicalAlias,
                                               icon: RoomAvatarImage(avatar: space.avatar,
                                                                     avatarSize: .room(on: .createRoomSelectSpace),
                                                                     mediaProvider: context.mediaProvider)),
                                kind: .selection(isSelected: context.selectedSpace?.id == space.id) {
                                    context.selectedSpace = space
                                    dismiss()
                                })
                    }
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 66)
            .scrollContentBackground(.hidden)
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .navigationTitle(L10n.screenCreateRoomSpaceSelectionSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarButton(role: .cancel) {
                        dismiss()
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(dragIndicatorVisibilty)
        }
    }
}

struct CreateRoomSpaceSelectionSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let clientProxy = ClientProxyMock(.init(userID: "@userid:example.com"))
        clientProxy.spaceService = SpaceServiceProxyMock(.init(editableSpaces: .mockJoinedSpaces2))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return CreateRoomScreenViewModel(isSpace: false,
                                         spaceSelectionMode: .editableSpacesList(preSelectedSpace: nil),
                                         shouldShowCancelButton: false,
                                         userSession: userSession,
                                         analytics: ServiceLocator.shared.analytics,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        CreateRoomSpaceSelectionSheet(context: viewModel.context)
            .snapshotPreferences(expect: viewModel.context.$viewState.map { $0.editableSpaces.count > 0 })
    }
}
