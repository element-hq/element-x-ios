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

struct ReportContentCoordinatorParameters {
    let itemID: String
    let roomProxy: RoomProxyProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
}

enum ReportContentCoordinatorAction {
    case cancel
    case finish
}

final class ReportContentCoordinator: CoordinatorProtocol {
    private let parameters: ReportContentCoordinatorParameters
    private var viewModel: ReportContentViewModelProtocol
    
    var callback: ((ReportContentCoordinatorAction) -> Void)?
    
    init(parameters: ReportContentCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ReportContentViewModel(itemID: parameters.itemID, roomProxy: parameters.roomProxy)
    }

    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .submitStarted:
                self.startLoading()
            case let .submitFailed(error):
                self.stopLoading()
                self.showError(description: error.localizedDescription)
            case .submitFinished:
                self.stopLoading()
                self.callback?(.finish)
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }

    func stop() {
        stopLoading()
    }
        
    func toPresentable() -> AnyView {
        AnyView(ReportContentScreen(context: viewModel.context))
    }

    // MARK: - Private

    private static let loadingIndicatorIdentifier = "ReportContentLoading"

    private func startLoading() {
        parameters.userIndicatorController?.submitIndicator(
            UserIndicator(id: Self.loadingIndicatorIdentifier,
                          type: .modal,
                          title: ElementL10n.sending,
                          persistent: true)
        )
    }

    private func stopLoading() {
        parameters.userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }

    private func showError(description: String) {
        parameters.userIndicatorController?.submitIndicator(UserIndicator(title: description))
    }
}
