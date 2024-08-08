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

// periphery:ignore:all - this is just a pinnedEventsTimeline remove this comment once generating the final file

import Combine
import SwiftUI

struct PinnedEventsTimelineScreenCoordinatorParameters { }

enum PinnedEventsTimelineScreenCoordinatorAction {
    case dismiss
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class PinnedEventsTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: PinnedEventsTimelineScreenCoordinatorParameters
    private let viewModel: PinnedEventsTimelineScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<PinnedEventsTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PinnedEventsTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = PinnedEventsTimelineScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                self.actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PinnedEventsTimelineScreen(context: viewModel.context))
    }
}
