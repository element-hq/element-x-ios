//
// Copyright 2021 New Vector Ltd
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
import SwiftUI

enum AnalyticsPromptScreenCoordinatorAction {
    case done
}

final class AnalyticsPromptScreenCoordinator: CoordinatorProtocol {
    private let analytics: AnalyticsService
    private var viewModel: AnalyticsPromptScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AnalyticsPromptScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AnalyticsPromptScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(analytics: AnalyticsService, termsURL: URL) {
        self.analytics = analytics
        viewModel = AnalyticsPromptScreenViewModel(termsURL: termsURL)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .enable:
                    MXLog.info("Enable Analytics")
                    analytics.optIn()
                    actionsSubject.send(.done)
                case .disable:
                    MXLog.info("Disable Analytics")
                    analytics.optOut()
                    actionsSubject.send(.done)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AnalyticsPromptScreen(context: viewModel.context))
    }
}
