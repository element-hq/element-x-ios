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

import Foundation

// MARK: View model

enum SessionVerificationViewModelAction {
    case finished
}

// MARK: View

struct SessionVerificationViewState: BindableState {
    var verificationState: SessionVerificationStateMachine.State = .initial
    
    var title: String? {
        switch verificationState {
        case .showingChallenge:
            return ElementL10n.sessionVerificationScreenEmojisTitle
        default:
            return nil
        }
    }
    
    var message: String {
        switch verificationState {
        case .initial:
            return ElementL10n.verificationOpenOtherToVerify
        case .requestingVerification:
            return ElementL10n.verificationRequestWaiting
        case .acceptingChallenge:
            return ElementL10n.verificationRequestWaiting
        case .decliningChallenge:
            return ElementL10n.verificationRequestWaiting
        case .cancelling:
            return ElementL10n.verificationRequestWaiting
        case .showingChallenge:
            return ElementL10n.sessionVerificationScreenEmojisMessage
        case .verified:
            return ElementL10n.verificationConclusionOkSelfNotice
        case .cancelled:
            return ElementL10n.verificationCancelled
        }
    }
}

enum SessionVerificationViewAction {
    case start
    case restart
    case accept
    case decline
    case close
}
