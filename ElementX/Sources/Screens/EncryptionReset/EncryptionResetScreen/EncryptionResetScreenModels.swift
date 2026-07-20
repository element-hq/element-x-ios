//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum EncryptionResetScreenViewModelAction {
    case requestPassword(passwordPublisher: PassthroughSubject<String, Never>)
    case requestOAuthAuthorisation(url: URL)
    case resetFinished
    case cancel
}

struct EncryptionResetScreenViewState: BindableState {
    var bindings: EncryptionResetScreenViewStateBindings
}

struct EncryptionResetScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetScreenViewAction {
    case reset
    case cancel
}
