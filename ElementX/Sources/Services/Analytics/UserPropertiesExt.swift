//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AnalyticsEvents
import Foundation

extension AnalyticsEvent {
    static func newVerificationStateUserProperty(verificationState: SessionVerificationState, recoveryState: SecureBackupRecoveryState) -> UserProperties {
        let analyticsVerificationState: AnalyticsEvent.UserProperties.VerificationState? = switch verificationState {
        case .unknown:
            nil
        case .verified:
            .Verified
        case .unverified:
            .NotVerified
        }
        
        let analyticsRecoveryState: AnalyticsEvent.UserProperties.RecoveryState? = switch recoveryState {
        case .enabled:
            .Enabled
        case .disabled:
            .Disabled
        case .incomplete:
            .Incomplete
        case .unknown:
            nil
        case .settingUp:
            nil
        }
        
        return UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: nil, numFavouriteRooms: nil, numSpaces: nil, recoveryState: analyticsRecoveryState, verificationState: analyticsVerificationState)
    }
}
