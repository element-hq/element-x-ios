//
// Copyright 2024 New Vector Ltd
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
