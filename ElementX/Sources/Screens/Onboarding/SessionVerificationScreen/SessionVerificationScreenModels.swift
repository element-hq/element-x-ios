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

struct SessionVerificationScreenViewState: BindableState {
    let flow: SessionVerificationScreenFlow
    var verificationState: SessionVerificationScreenStateMachine.State
    
    var headerImageName: String {
        switch verificationState {
        case .initial:
            return "lock"
        case .acceptingVerificationRequest:
            return "hourglass"
        case .requestingVerification:
            return "hourglass"
        case .verificationRequestAccepted:
            return "face.smiling"
        case .startingSasVerification:
            return "hourglass"
        case .sasVerificationStarted:
            return "hourglass"
        case .cancelling:
            return "hourglass"
        case .acceptingChallenge:
            return "hourglass"
        case .decliningChallenge:
            return "hourglass"
        case .showingChallenge:
            return "face.smiling"
        case .verified:
            return "checkmark.shield"
        case .cancelled:
            return "exclamationmark.shield"
        }
    }
    
    var title: String? {
        switch verificationState {
        case .initial:
            switch flow {
            case .initiator:
                return L10n.screenSessionVerificationOpenExistingSessionTitle
            case .responder:
                return L10n.screenSessionVerificationRequestTitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationRequestTitle
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
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .verified:
            return L10n.commonVerificationComplete
        case .cancelling:
            return nil
        case .cancelled:
            return L10n.commonVerificationFailed
        }
    }
    
    var titleAccessibilityIdentifier: String {
        verificationState == .verified ? A11yIdentifiers.sessionVerificationScreen.verificationComplete : ""
    }
        
    var message: String {
        switch verificationState {
        case .initial:
            switch flow {
            case .initiator:
                return L10n.screenSessionVerificationOpenExistingSessionSubtitle
            case .responder:
                return L10n.screenSessionVerificationRequestSubtitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationRequestSubtitle
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
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .cancelling:
            return L10n.commonWaiting
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .verified:
            return L10n.screenSessionVerificationCompleteSubtitle
        case .cancelled:
            return L10n.screenSessionVerificationFailedSubtitle
        }
    }
}
