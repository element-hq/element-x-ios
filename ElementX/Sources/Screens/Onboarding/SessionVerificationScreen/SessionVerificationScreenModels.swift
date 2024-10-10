//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum SessionVerificationScreenViewModelAction {
    case finished
}

struct SessionVerificationScreenViewState: BindableState {
    let flow: SessionVerificationScreenFlow
    var verificationState: SessionVerificationScreenStateMachine.State
}

enum SessionVerificationScreenViewAction {
    case acceptVerificationRequest
    case ignoreVerificationRequest
    case requestVerification
    case startSasVerification
    case restart
    case accept
    case decline
    case done
}
