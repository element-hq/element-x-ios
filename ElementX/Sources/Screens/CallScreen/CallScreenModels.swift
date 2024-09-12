//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVKit
import Foundation

enum CallScreenViewModelAction {
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case pictureInPictureStarted
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
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case navigateBack
    case pictureInPictureWillStop
    case endCall
}

enum CallScreenError: Error {
    case pictureInPictureNotAvailable
}
