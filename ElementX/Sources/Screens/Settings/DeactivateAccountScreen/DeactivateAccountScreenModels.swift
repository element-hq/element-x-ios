//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DeactivateAccountScreenViewModelAction {
    case accountDeactivated
}

/// Reauthentication phase used to gate deactivation. Mirrors the Matrix
/// `m.login.msisdn` UIA stage — we must prove possession of the linked phone
/// before honouring the destructive request.
enum DeactivateAccountReauthPhase: Equatable {
    /// Ready to send the OTP. Initial state and after a failed/cancelled attempt.
    case idle
    /// OTP is being sent to the linked phone.
    case sendingCode
    /// OTP has been sent; waiting for the user to enter it.
    case awaitingCode
    /// Code is being verified.
    case verifyingCode
    /// Reauth verified; ready to deactivate.
    case verified
    /// Server returned an error in any of the steps.
    case error(String)
}

struct DeactivateAccountScreenViewState: BindableState {
    let info: AttributedString
    let infoPoint1: AttributedString
    let infoPoint2 = AttributedString(L10n.screenDeactivateAccountListItem2)
    let infoPoint3 = AttributedString(L10n.screenDeactivateAccountListItem3)
    let infoPoint4 = AttributedString(L10n.screenDeactivateAccountListItem4)

    /// True only when the identity-service client is configured. When false we fall back to the
    /// SDK's legacy password flow (preserved for development environments without a backend).
    let identityServiceAvailable: Bool

    var reauthPhase: DeactivateAccountReauthPhase = .idle
    var bindings = DeactivateAccountScreenViewStateBindings()
    
    init(identityServiceAvailable: Bool = false) {
        self.identityServiceAvailable = identityServiceAvailable

        let boldPlaceholder = "{bold}"
        var attributedString = AttributedString(L10n.screenDeactivateAccountDescription(boldPlaceholder))
        var boldString = AttributedString(L10n.screenDeactivateAccountDescriptionBoldPart)
        boldString.bold()
        attributedString.replace(boldPlaceholder, with: boldString)
        info = attributedString
        
        attributedString = AttributedString(L10n.screenDeactivateAccountListItem1(boldPlaceholder))
        boldString = AttributedString(L10n.screenDeactivateAccountListItem1BoldPart)
        boldString.bold()
        attributedString.replace(boldPlaceholder, with: boldString)
        infoPoint1 = attributedString
    }
}

struct DeactivateAccountScreenViewStateBindings {
    var password = ""
    var eraseData = false
    var otpCode = ""
    var alertInfo: AlertInfo<DeactivateAccountScreenAlert>?
}

enum DeactivateAccountScreenAlert {
    case confirmation
    case deactivationFailed
}

enum DeactivateAccountScreenViewAction {
    case deactivate
    case sendReauthCode
    case verifyReauthCode
}
