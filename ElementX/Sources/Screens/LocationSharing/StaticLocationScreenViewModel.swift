//
// Copyright 2023 New Vector Ltd
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
                                                 secondaryButton: .init(title: L10n.actionOpenSettings, action: action))
            }
        }
    }
}
