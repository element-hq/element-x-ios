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

import AVKit
import Foundation

enum CallScreenViewModelAction {
    case pictureInPictureStarted(AVPictureInPictureController)
    case pictureInPictureStopped
    case dismiss
}

struct CallScreenViewState: BindableState {
    let messageHandler: String
    let script: String?
    var url: URL?
    
    let certificateValidator: CertificateValidatorHookProtocol
    
    var bindings = Bindings()
}

struct Bindings {
    var javaScriptMessageHandler: ((Any) -> Void)?
    var javaScriptEvaluator: ((String) async throws -> Any)?
    var requestPictureInPictureHandler: (() async -> Result<AVPictureInPictureController, CallScreenError>)?
    
    var alertInfo: AlertInfo<UUID>?
}

enum CallScreenViewAction {
    case urlChanged(URL?)
    case navigateBack
    case pictureInPictureWillStop
    case endCall
}

enum CallScreenError: Error {
    case pictureInPictureNotAvailable
}
