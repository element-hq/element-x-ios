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
    
    var titleAccessibilityIdentifier: String {
        verificationState == .verified ? A11yIdentifiers.sessionVerificationScreen.verificationComplete : ""
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
}
