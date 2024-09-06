//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

typealias StaticLocationScreenViewModelType = StateStoreViewModel<StaticLocationScreenViewState, StaticLocationScreenViewAction>

class StaticLocationScreenViewModel: StaticLocationScreenViewModelType, StaticLocationScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<StaticLocationScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<StaticLocationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(interactionMode: StaticLocationInteractionMode) {
        super.init(initialViewState: .init(interactionMode: interactionMode))
    }
    
    override func process(viewAction: StaticLocationScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .selectLocation:
            guard let coordinate = state.bindings.mapCenterLocation else { return }
            let uncertainty = state.isSharingUserLocation ? context.geolocationUncertainty : nil
            actionsSubject.send(.sendLocation(.init(coordinate: coordinate, uncertainty: uncertainty), isUserLocation: state.isSharingUserLocation))
        case .userDidPan:
            state.bindings.showsUserLocationMode = .show
        case .centerToUser:
            switch state.bindings.isLocationAuthorized {
            case .some(true), .none:
                state.bindings.showsUserLocationMode = .showAndFollow
            case .some(false):
                let action: () -> Void = { [weak self] in self?.actionsSubject.send(.openSystemSettings) }
                state.bindings.alertInfo = .init(locationSharingViewError: .missingAuthorization,
                                                 primaryButton: .init(title: L10n.actionNotNow, role: .cancel, action: nil),
                                                 secondaryButton: .init(title: L10n.commonSettings, action: action))
            }
        }
    }
}
