//
// Copyright 2023 New Vector Ltd
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

enum MediaPickerScreenSource {
    case camera
    case photoLibrary
    case documents
}

enum MediaPickerScreenCoordinatorAction {
    case selectMediaAtURL(URL)
    case cancel
    case error(Error?)
}

class MediaPickerScreenCoordinator: CoordinatorProtocol {
    private let source: MediaPickerScreenSource
    private let callback: ((MediaPickerScreenCoordinatorAction) -> Void)?
    
    init(source: MediaPickerScreenSource, callback: @escaping (MediaPickerScreenCoordinatorAction) -> Void) {
        self.source = source
        self.callback = callback
    }
    
    func toPresentable() -> AnyView {
        AnyView(mediaPicker)
    }
    
    @ViewBuilder
    private var mediaPicker: some View {
        switch source {
        case .camera:
            cameraPicker
        case .photoLibrary:
            PhotoLibraryPicker { [weak self] action in
                switch action {
                case .cancel:
                    self?.callback?(.cancel)
                case .error(let error):
                    self?.callback?(.error(error))
                case .selectFile(let url):
                    self?.callback?(.selectMediaAtURL(url))
                }
            }
        case .documents:
            // The document picker automatically dismisses everything on selection
            // Strongly retain self in the callback to forward actions correctly
            DocumentPicker { action in
                switch action {
                case .cancel:
                    self.callback?(.cancel)
                case .error(let error):
                    self.callback?(.error(error))
                case .selectFile(let url):
                    self.callback?(.selectMediaAtURL(url))
                }
            }
        }
    }
    
    private var cameraPicker: some View {
        CameraPicker { [weak self] action in
            switch action {
            case .cancel:
                self?.callback?(.cancel)
            case .error(let error):
                self?.callback?(.error(error))
            case .selectFile(let url):
                self?.callback?(.selectMediaAtURL(url))
            }
        }
        .background(.black, ignoresSafeAreaEdges: .bottom)
    }
}
