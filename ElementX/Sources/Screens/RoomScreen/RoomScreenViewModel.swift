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

import Combine
import Foundation
import SwiftUI

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() {
        super.init(initialViewState: .init(bindings: .init()))
    }
    
    func loadDraft() {
        actionsSubject.send(.composer(action: .loadDraft))
    }
    
    func saveDraft() {
        actionsSubject.send(.composer(action: .saveDraft))
    }
}

extension RoomScreenViewModel {
    static func mock() -> RoomScreenViewModel {
        RoomScreenViewModel()
    }
}

private struct RoomContextKey: EnvironmentKey {
    @MainActor static let defaultValue: RoomScreenViewModel.Context? = nil
}

extension EnvironmentValues {
    /// Used to access and inject the room context without observing it
    var roomContext: RoomScreenViewModel.Context? {
        get { self[RoomContextKey.self] }
        set { self[RoomContextKey.self] = newValue }
    }
}
