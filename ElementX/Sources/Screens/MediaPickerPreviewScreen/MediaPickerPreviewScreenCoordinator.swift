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

struct MediaPickerPreviewScreenCoordinatorParameters {
    let url: URL
    let title: String?
}

enum MediaPickerPreviewScreenCoordinatorAction {
    case send
    case cancel
}

final class MediaPickerPreviewScreenCoordinator: CoordinatorProtocol {
    private let parameters: MediaPickerPreviewScreenCoordinatorParameters
    
    private var viewModel: MediaPickerPreviewScreenViewModelProtocol
    private let callback: (MediaPickerPreviewScreenCoordinatorAction) -> Void
    
    init(parameters: MediaPickerPreviewScreenCoordinatorParameters, callback: @escaping (MediaPickerPreviewScreenCoordinatorAction) -> Void) {
        self.parameters = parameters
        self.callback = callback
        
        viewModel = MediaPickerPreviewScreenViewModel(url: parameters.url, title: parameters.title)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            switch action {
            case .send:
                self?.callback(.send)
            case .cancel:
                self?.callback(.cancel)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(MediaPickerPreviewScreen(context: viewModel.context))
    }
}
