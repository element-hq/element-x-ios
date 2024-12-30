//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct TimelineMediaPreviewContext {
    /// The initial item to preview from the provided timeline.
    /// This item's `id` will be used as the navigation transition's `sourceID`.
    let item: EventBasedMessageTimelineItemProtocol
    /// The timeline that the preview comes from, to allow for swiping to other media.
    let viewModel: TimelineViewModelProtocol
    /// The namespace that the navigation transition's `sourceID` should be defined in.
    let namespace: Namespace.ID
    /// A closure to be called whenever a different preview item is shown. It should also
    /// be called *after* the preview has been dismissed, with an ID of `nil`.
    ///
    /// This helps work around a bug caused by the flipped scrollview where the zoomed
    /// thumbnail starts off upside down while loading the preview screen.
    var itemIDHandler: ((TimelineItemIdentifier?) -> Void)?
}

struct TimelineMediaPreviewCoordinatorParameters {
    let context: TimelineMediaPreviewContext
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appMediator: AppMediatorProtocol
}

enum TimelineMediaPreviewCoordinatorAction {
    case viewInRoomTimeline(TimelineItemIdentifier)
    case dismiss
}

final class TimelineMediaPreviewCoordinator: CoordinatorProtocol {
    private let parameters: TimelineMediaPreviewCoordinatorParameters
    private let viewModel: TimelineMediaPreviewViewModel
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TimelineMediaPreviewCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: TimelineMediaPreviewCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = TimelineMediaPreviewViewModel(context: parameters.context,
                                                  mediaProvider: parameters.mediaProvider,
                                                  photoLibraryManager: PhotoLibraryManager(),
                                                  userIndicatorController: parameters.userIndicatorController,
                                                  appMediator: parameters.appMediator)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .viewInRoomTimeline(let itemID):
                actionsSubject.send(.viewInRoomTimeline(itemID))
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        // Calling the completion onDisappear isn't ideal, but we don't push away from the screen so it should be
        // a good enough approximation of didDismiss, given that the only other option is our navigation callbacks
        // which are essentially willDismiss callbacks and happen too early for this particular completion handler.
        AnyView(TimelineMediaPreviewScreen(context: viewModel.context, itemIDHandler: parameters.context.itemIDHandler))
    }
}
