//
// Copyright 2023 New Vector Ltd
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

import LocalAuthentication
import SFSafeSymbols

extension LABiometryType {
    /// The SF Symbol that represents the biometry type.
    var systemSymbol: SFSymbol {
        switch self {
        case .none: {
                MXLog.error("Invalid presentation: Biometrics not supported.")
                return .viewfinder
            }()
        case .touchID: .touchid
        case .faceID: .faceid
        case .opticID: SFSymbol(rawValue: "opticid")
        @unknown default: .viewfinder
        }
    }
    
    /// The localized string for the biometry type.
    var localizedString: String {
        switch self {
        case .none: {
                MXLog.error("Invalid presentation: Biometrics not supported.")
                return L10n.screenAppLockBiometricUnlock
            }()
        case .touchID: L10n.commonTouchIdIos
        case .faceID: L10n.commonFaceIdIos
        case .opticID: L10n.commonOpticIdIos
        @unknown default: L10n.screenAppLockBiometricUnlock
        }
    }
}
