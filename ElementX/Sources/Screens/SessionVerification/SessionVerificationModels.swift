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

enum SessionVerificationViewModelAction {
    case finished
}

struct SessionVerificationViewState: BindableState {
    var verificationState: SessionVerificationStateMachine.State = .initial
    
    var title: String? {
        switch verificationState {
        case .initial:
            return ElementL10n.verificationOpenOtherToVerifyTitle
        case .requestingVerification:
            return ElementL10n.verificationRequestWaitingAcceptRequestTitle
        case .verificationRequestAccepted:
            return ElementL10n.verificationCompareEmojisTitle
        case .startingSasVerification:
            return nil
        case .sasVerificationStarted:
            return nil
        case .showingChallenge:
            return ElementL10n.verificationCompareEmojisTitle
        case .acceptingChallenge:
            return ElementL10n.verificationCompareEmojisTitle
        case .decliningChallenge:
            return nil
        case .verified:
            return ElementL10n.verificationConclusionOkSelfNoticeTitle
        case .cancelling:
            return nil
        case .cancelled:
            return ElementL10n.verificationCancelled
        }
    }
        
    var message: String {
        switch verificationState {
        case .initial:
            return ElementL10n.verificationOpenOtherToVerifyDetail
        case .requestingVerification:
            return ElementL10n.verificationRequestWaitingAcceptRequestDetail
        case .verificationRequestAccepted:
            return ElementL10n.verificationEmojiNotice
        case .startingSasVerification:
            return L10n.commonWaiting
        case .sasVerificationStarted:
            return L10n.commonWaiting
        case .acceptingChallenge:
            return ElementL10n.verificationCompareEmojisDetail
        case .decliningChallenge:
            return L10n.commonWaiting
        case .cancelling:
            return L10n.commonWaiting
        case .showingChallenge:
            return ElementL10n.verificationCompareEmojisDetail
        case .verified:
            return ElementL10n.verificationConclusionOkSelfNotice
        case .cancelled:
            return ElementL10n.verificationRequestCancelledDetail
        }
    }
}

enum SessionVerificationViewAction {
    case requestVerification
    case startSasVerification
    case restart
    case accept
    case decline
    case close
}
