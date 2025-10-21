//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    case cancel
    case done
}

struct SessionVerificationScreenViewState: BindableState {
    let flow: SessionVerificationScreenFlow
    let learnMoreURL: URL
    
    var verificationState: SessionVerificationScreenStateMachine.State
    
    var headerIcon: (keyPath: KeyPath<CompoundIcons, Image>, style: BigIcon.Style) {
        switch verificationState {
        case .initial:
            switch flow {
            case .deviceInitiator, .deviceResponder:
                return (\.devices, .defaultSolid)
            case .userInitiator, .userResponder:
                return (\.userProfileSolid, .defaultSolid)
            }
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
    
    var titleAccessibilityIdentifier: String {
        verificationState == .verified ? A11yIdentifiers.sessionVerificationScreen.verificationComplete : ""
    }
    
    var title: String? {
        switch verificationState {
        case .initial:
            switch flow {
            case .deviceInitiator:
                return L10n.screenSessionVerificationUseAnotherDeviceTitle
            case .userInitiator:
                return L10n.screenSessionVerificationUserInitiatorTitle
            case .deviceResponder, .userResponder:
                return L10n.screenSessionVerificationRequestTitle
            }
        case .acceptingVerificationRequest:
            return waitingTitle
        case .requestingVerification:
            return waitingTitle
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .startingSasVerification:
            return waitingTitle
        case .sasVerificationStarted:
            return waitingTitle
        case .showingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .decliningChallenge:
            return L10n.screenSessionVerificationCompareEmojisTitle
        case .verified:
            switch flow {
            case .deviceInitiator, .deviceResponder:
                return L10n.screenSessionVerificationDeviceVerified
            case .userInitiator, .userResponder:
                return L10n.commonVerificationComplete
            }
        case .cancelling:
            return waitingTitle
        case .cancelled:
            return L10n.commonVerificationFailed
        }
    }
    
    private var waitingTitle: String {
        switch flow {
        case .deviceInitiator, .deviceResponder:
            return L10n.screenSessionVerificationWaitingOtherDeviceTitle
        case .userInitiator, .userResponder:
            return L10n.screenSessionVerificationWaitingOtherUserTitle
        }
    }
        
    var message: String {
        switch verificationState {
        case .initial:
            switch flow {
            case .deviceInitiator:
                return L10n.screenSessionVerificationUseAnotherDeviceSubtitle
            case .userInitiator:
                return L10n.screenSessionVerificationUserInitiatorSubtitle
            case .deviceResponder:
                return L10n.screenSessionVerificationRequestSubtitle
            case .userResponder:
                return L10n.screenSessionVerificationUserResponderSubtitle
            }
        case .acceptingVerificationRequest:
            return waitingMessage
        case .requestingVerification:
            return waitingMessage
        case .verificationRequestAccepted:
            return L10n.screenSessionVerificationRequestAcceptedSubtitle
        case .startingSasVerification:
            return waitingMessage
        case .sasVerificationStarted:
            return waitingMessage
        case .acceptingChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .decliningChallenge:
            return L10n.screenSessionVerificationCompareEmojisSubtitle
        case .cancelling:
            return waitingMessage
        case .showingChallenge:
            switch flow {
            case .deviceInitiator, .deviceResponder:
                return L10n.screenSessionVerificationCompareEmojisSubtitle
            case .userInitiator, .userResponder:
                return L10n.screenSessionVerificationCompareEmojisUserSubtitle
            }
        case .verified:
            switch flow {
            case .deviceInitiator, .deviceResponder:
                return L10n.screenSessionVerificationCompleteSubtitle
            case .userInitiator, .userResponder:
                return L10n.screenSessionVerificationCompleteUserSubtitle
            }
            
        case .cancelled:
            return L10n.screenSessionVerificationFailedSubtitle
        }
    }
    
    private var waitingMessage: String {
        L10n.screenSessionVerificationWaitingSubtitle
    }
}
