//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EditRoomAddressScreen: View {
    @ObservedObject var context: EditRoomAddressScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                EditRoomAddressListRow(aliasLocalPart: $context.desiredAliasLocalPart,
                                       serverName: context.viewState.serverName, shouldDisplayError: context.viewState.aliasErrors.errorDescription != nil)
                    .onChange(of: context.desiredAliasLocalPart) { _, newAliasLocalPart in
                        context.desiredAliasLocalPart = newAliasLocalPart.lowercased()
                    }
                    .onSubmit {
                        if context.viewState.canSave {
                            context.send(viewAction: .save)
                        }
                    }
            } footer: {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorDescription = context.viewState.aliasErrors.errorDescription {
                        Label(errorDescription, icon: \.error, iconSize: .xSmall, relativeTo: .compound.bodySM)
                            .foregroundStyle(.compound.textCriticalPrimary)
                            .font(.compound.bodySM)
                    }
                    Text(L10n.screenCreateRoomRoomAddressSectionFooter)
                        .compoundListSectionFooter()
                        .font(.compound.bodySM)
                }
            }
        }
        .compoundList()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.screenEditRoomAddressTitle)
        .toolbar { toolbar }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
            }
            .disabled(!context.viewState.canSave)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct EditRoomAddressScreen_Previews: PreviewProvider, TestablePreview {
    static let noAliasviewModel = EditRoomAddressScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Room Name")),
                                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                                 userIndicatorController: UserIndicatorControllerMock())
    
    static let aliasviewModel = EditRoomAddressScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#room-alias:matrix.org")),
                                                               clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                               userIndicatorController: UserIndicatorControllerMock())
    
    static let invalidSymbolsViewModel = EditRoomAddressScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Room Name", canonicalAlias: "#room#-alias:matrix.org")),
                                                                        clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                                        userIndicatorController: UserIndicatorControllerMock())
    
    static let alreadyExistingViewModel = {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "matrix.org"))
        clientProxy.isAliasAvailableReturnValue = .success(false)
        return EditRoomAddressScreenViewModel(initialViewState: .init(serverName: "matrix.org",
                                                                      bindings: .init(desiredAliasLocalPart: "whatever")),
                                              roomProxy: JoinedRoomProxyMock(.init(name: "Room Name")),
                                              clientProxy: clientProxy,
                                              userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static var previews: some View {
        NavigationStack {
            EditRoomAddressScreen(context: noAliasviewModel.context)
        }
        .previewDisplayName("No alias")
        
        NavigationStack {
            EditRoomAddressScreen(context: aliasviewModel.context)
        }
        .previewDisplayName("With alias")
        
        NavigationStack {
            EditRoomAddressScreen(context: invalidSymbolsViewModel.context)
        }
        .snapshotPreferences(expect: invalidSymbolsViewModel.context.$viewState.map { state in
            !state.aliasErrors.isEmpty
        })
        .previewDisplayName("Invalid symbols")
        
        NavigationStack {
            EditRoomAddressScreen(context: alreadyExistingViewModel.context)
        }
        .snapshotPreferences(expect: alreadyExistingViewModel.context.$viewState.map { state in
            !state.aliasErrors.isEmpty
        })
        .previewDisplayName("Already existing")
    }
}
