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

enum SessionVerificationScreenViewModelAction {
    case finished
}

struct SessionVerificationScreenViewState: BindableState {
    var verificationState: SessionVerificationScreenStateMachine.State = .initial
    
    var title: String? {
        switch verificationState {
        case .initial:
            return L10n.screenSessionVerificationOpenExistingSessionTitle
        case .requestingVerification:
            return L10n.screenSessionVerificationWaitingToAcceptTitle
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .startingSasVerification:
            return nil
        case .sasVerificationStarted:
            return nil
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .decliningChallenge:
            return nil
        case .verified:
            return L10n.commonVerificationComplete
        case .cancelling:
            return nil
        case .cancelled:
            return L10n.commonVerificationCancelled
        }
    }
        
    var message: String {
        switch verificationState {
        case .initial:
            return L10n.screenSessionVerificationOpenExistingSessionSubtitle
        case .requestingVerification:
            return L10n.screenSessionVerificationWaitingToAcceptSubtitle
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationRequestAcceptedSubtitle
        case .startingSasVerification:
            return L10n.commonWaiting
        case .sasVerificationStarted:
            return L10n.commonWaiting
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .decliningChallenge:
            return L10n.commonWaiting
        case .cancelling:
            return L10n.commonWaiting
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .verified:
            return L10n.screenSessionVerificationCompleteSubtitle
        case .cancelled:
            return L10n.screenSessionVerificationCancelledSubtitle
        }
    }
}

enum SessionVerificationScreenViewAction {
    case requestVerification
    case startSasVerification
    case restart
    case accept
    case decline
    case close
}
