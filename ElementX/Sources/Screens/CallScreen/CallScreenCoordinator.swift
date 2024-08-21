//
// Copyright 2022 New Vector Ltd
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

import AVKit
import Combine
import SwiftUI

struct CallScreenCoordinatorParameters {
    let elementCallService: ElementCallServiceProtocol
    let configuration: ElementCallConfiguration
    let elementCallPictureInPictureEnabled: Bool
    let appHooks: AppHooks
}

enum CallScreenCoordinatorAction {
    /// The call is still ongoing but the user wishes to navigate around the app.
    case pictureInPictureStarted(AVPictureInPictureController)
    /// The call is hidden and the user wishes to return to it.
    case pictureInPictureStopped
    /// The call is finished and the screen is done with.
    case dismiss
}

final class CallScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CallScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<CallScreenCoordinatorAction, Never> = .init()
    
    private var cancellables: Set<AnyCancellable> = .init()
    var actions: AnyPublisher<CallScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CallScreenCoordinatorParameters) {
        viewModel = CallScreenViewModel(elementCallService: parameters.elementCallService,
                                        configuration: parameters.configuration,
                                        elementCallPictureInPictureEnabled: parameters.elementCallPictureInPictureEnabled,
                                        appHooks: parameters.appHooks)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .pictureInPictureStarted(let controller):
                actionsSubject.send(.pictureInPictureStarted(controller))
            case .pictureInPictureStopped:
                actionsSubject.send(.pictureInPictureStopped)
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(CallScreen(context: viewModel.context))
    }
}
