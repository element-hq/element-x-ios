//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVKit
import Combine
import SwiftUI

struct CallScreenCoordinatorParameters {
    let elementCallService: ElementCallServiceProtocol
    let configuration: ElementCallConfiguration
    let allowPictureInPicture: Bool
    let appHooks: AppHooks
}

enum CallScreenCoordinatorAction {
    /// The call is able to be minimised to picture in picture with the provided controller.
    ///
    /// **Note:** Manually starting the PiP will not trigger the action below as we don't want
    /// to change the app's navigation when backgrounding the app with the call screen visible.
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    /// The call is still ongoing but the user requested to navigate around the app.
    case pictureInPictureStarted
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
                                        allowPictureInPicture: parameters.allowPictureInPicture,
                                        appHooks: parameters.appHooks)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .pictureInPictureIsAvailable(let controller):
                actionsSubject.send(.pictureInPictureIsAvailable(controller))
            case .pictureInPictureStarted:
                actionsSubject.send(.pictureInPictureStarted)
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
