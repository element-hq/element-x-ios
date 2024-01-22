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

// periphery:ignore:all - this is just a logViewer remove this comment once generating the final file

import Combine
import SwiftUI

struct LogViewerScreenCoordinatorParameters { }

enum LogViewerScreenCoordinatorAction {
    case done
}

final class LogViewerScreenCoordinator: CoordinatorProtocol {
    private let parameters: LogViewerScreenCoordinatorParameters
    private var viewModel: LogViewerScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<LogViewerScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<LogViewerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: LogViewerScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = LogViewerScreenViewModel()
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                self.actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(LogViewerScreen(context: viewModel.context))
    }
}
