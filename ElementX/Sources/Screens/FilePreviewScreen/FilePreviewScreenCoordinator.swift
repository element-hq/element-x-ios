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

struct FilePreviewCoordinatorScreenParameters {
    let mediaFile: MediaFileHandleProxy
    let title: String?
}

enum FilePreviewScreenCoordinatorAction {
    case cancel
}

final class FilePreviewScreenCoordinator: CoordinatorProtocol {
    private let parameters: FilePreviewCoordinatorScreenParameters
    private var viewModel: FilePreviewScreenViewModelProtocol

    var callback: ((FilePreviewScreenCoordinatorAction) -> Void)?
    
    init(parameters: FilePreviewCoordinatorScreenParameters) {
        self.parameters = parameters
        
        viewModel = FilePreviewScreenViewModel(mediaFile: parameters.mediaFile, title: parameters.title)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(FilePreviewScreen(context: viewModel.context))
    }
}
