//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

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
    
    var headerIcon: (keyPath: KeyPath<CompoundIcons, Image>, style: BigIcon.Style) {
        switch verificationState {
        case .initial:
            return (\.devices, .defaultSolid)
        case .acceptingVerificationRequest:
            return (\.devices, .defaultSolid)
        case .requestingVerification:
            return (\.devices, .defaultSolid)
        case .verificationRequestAccepted:
            return (\.reaction, .defaultSolid)
        case .startingSasVerification:
            return (\.devices, .defaultSolid)
        case .sasVerificationStarted:
            return (\.devices, .defaultSolid)
        case .cancelling:
            return (\.lockSolid, .defaultSolid)
        case .showingChallenge:
            return (\.reaction, .defaultSolid)
        case .acceptingChallenge:
            return (\.reaction, .defaultSolid)
        case .decliningChallenge:
            return (\.reaction, .defaultSolid)
        case .verified:
            return (\.checkCircleSolid, .successSolid)
        case .cancelled:
            return (\.infoSolid, .alertSolid)
        }
    }
    
    var title: String? {
        switch verificationState {
        case .initial:
            switch flow {
            case .initiator:
                return L10n.screenSessionVerificationUseAnotherDeviceTitle
            case .responder:
                return L10n.screenSessionVerificationRequestTitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationWaitingAnotherDeviceTitle
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
                return L10n.screenSessionVerificationUseAnotherDeviceSubtitle
            case .responder:
                return L10n.screenSessionVerificationRequestSubtitle
            }
        case .acceptingVerificationRequest:
            return L10n.screenSessionVerificationWaitingAnotherDeviceSubtitle
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
