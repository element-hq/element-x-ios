//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ManageAuthorizedSpacesScreenViewModelType = StateStoreViewModelV2<ManageAuthorizedSpacesScreenViewState, ManageAuthorizedSpacesScreenViewAction>

class ManageAuthorizedSpacesScreenViewModel: ManageAuthorizedSpacesScreenViewModelType, ManageAuthorizedSpacesScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<ManageAuthorizedSpacesScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ManageAuthorizedSpacesScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authorizedSpacesSelection: AuthorizedSpacesSelection,
         mediaProvider: MediaProviderProtocol) {
        super.init(initialViewState: ManageAuthorizedSpacesScreenViewState(authorizedSpacesSelection: authorizedSpacesSelection),
                   mediaProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: ManageAuthorizedSpacesScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
        case .done:
            state.authorizedSpacesSelection.selectedIDs.send(state.selectedIDs)
            actionsSubject.send(.dismiss)
        case .toggle(let spaceID):
            if state.selectedIDs.contains(spaceID) {
                state.selectedIDs.remove(spaceID)
            } else {
                state.selectedIDs.insert(spaceID)
            }
        }
    }
}
