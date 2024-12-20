//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias EditRoomAddressScreenViewModelType = StateStoreViewModel<EditRoomAddressScreenViewState, EditRoomAddressScreenViewAction>

class EditRoomAddressScreenViewModel: EditRoomAddressScreenViewModelType, EditRoomAddressScreenViewModelProtocol {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<EditRoomAddressScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EditRoomAddressScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        var aliasLocalPart = ""
        if let canonicalAlias = roomProxy.infoPublisher.value.canonicalAlias {
            aliasLocalPart = canonicalAlias.dropFirst().split(separator: ":").first.flatMap(String.init) ?? ""
        } else if let displayName = roomProxy.infoPublisher.value.displayName {
            aliasLocalPart = roomAliasNameFromRoomDisplayName(roomName: displayName)
        }
        
        super.init(initialViewState: EditRoomAddressScreenViewState(serverName: clientProxy.userIDServerName ?? "",
                                                                    desiredAliasLocalPart: aliasLocalPart))
    }
    
    // MARK: - Public
    
    override func process(viewAction: EditRoomAddressScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            // TODO: Handle the save action
            break
        case .cancel:
            actionsSubject.send(.cancel)
        case .updateAliasLocalPart(let updatedValue):
            break
        }
    }
}
