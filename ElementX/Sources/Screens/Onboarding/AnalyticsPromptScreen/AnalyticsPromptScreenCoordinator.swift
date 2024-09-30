//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
