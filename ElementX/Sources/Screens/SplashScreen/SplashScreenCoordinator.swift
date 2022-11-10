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

import SwiftUI

final class SplashScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SplashScreenViewModelProtocol
    
//    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
//    private var loadingIndicator: UserIndicator?
    
    var callback: ((SplashScreenCoordinatorAction) -> Void)?
    
    init() {
        viewModel = SplashScreenViewModel()
//        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: splashScreenHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            MXLog.debug("SplashScreenViewModel did complete with result: \(action).")
            guard let self else { return }
            switch action {
            case .login:
                self.callback?(.login)
            }
        }
    }
    
    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(SplashScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
//        loadingIndicator = indicatorPresenter.present(.loading(label: ElementL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
//        loadingIndicator = nil
    }
}
