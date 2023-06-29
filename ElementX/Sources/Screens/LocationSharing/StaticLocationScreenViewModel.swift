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
            actionsSubject.send(.sendLocation(.init(coordinate: coordinate)))
        case .userDidPan:
            state.showsUserLocationMode = .hide
            state.isPinDropSharing = true
        }
    }
}
