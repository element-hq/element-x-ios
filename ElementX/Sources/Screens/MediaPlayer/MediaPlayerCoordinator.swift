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

struct MediaPlayerCoordinatorParameters {
    let mediaURL: URL
}

enum MediaPlayerCoordinatorAction {
    case cancel
}

final class MediaPlayerCoordinator: CoordinatorProtocol {
    private let parameters: MediaPlayerCoordinatorParameters
    private var viewModel: MediaPlayerViewModelProtocol
    
    var callback: ((MediaPlayerCoordinatorAction) -> Void)?
    
    init(parameters: MediaPlayerCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = MediaPlayerViewModel(mediaURL: parameters.mediaURL)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("Did start.")
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("MediaPlayerViewModel did complete with result: \(action).")
            switch action {
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(MediaPlayerScreen(context: viewModel.context))
    }
}
