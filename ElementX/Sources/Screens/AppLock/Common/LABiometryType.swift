//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
