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

struct ImageViewerCoordinatorParameters {
    let navigationController: NavigationController
    let image: UIImage
    let isModallyPresented: Bool
}

enum ImageViewerCoordinatorAction {
    case cancel
}

final class ImageViewerCoordinator: CoordinatorProtocol {
    private let parameters: ImageViewerCoordinatorParameters
    private var viewModel: ImageViewerViewModelProtocol
    
    var callback: ((ImageViewerCoordinatorAction) -> Void)?
    
    init(parameters: ImageViewerCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ImageViewerViewModel(image: parameters.image,
                                         isModallyPresented: parameters.isModallyPresented)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("ImageViewerViewModel did complete with result: \(action).")
            switch action {
            case .cancel:
                self.callback?(.cancel)
            case .share:
                self.presentShareImage()
            }
        }
    }

    func toPresentable() -> AnyView {
        AnyView(ImageViewerScreen(context: viewModel.context))
    }

    private func presentShareImage() {
        parameters.navigationController.presentSheet(ActivityCoordinator(items: [parameters.image]))
    }
}
