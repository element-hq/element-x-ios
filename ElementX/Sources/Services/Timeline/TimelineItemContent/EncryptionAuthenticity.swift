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

import Compound
import MatrixRustSDK
import SwiftUI

/// Represents and issue with a timeline item's authenticity such as coming from an
/// unsigned session or being sent unencrypted in an encrypted room. See Rust's
/// `ShieldStateCode` for more information about the meaning of the cases.
enum EncryptionAuthenticity: Hashable {
    enum Color { case red, gray }
    
    case notGuaranteed(color: Color)
    case unknownDevice(color: Color)
    case unsignedDevice(color: Color)
    case unverifiedIdentity(color: Color)
    case previouslyVerified(color: Color)
    case sentInClear(color: Color)
    
    var message: String {
        switch self {
        case .notGuaranteed:
            L10n.eventShieldReasonAuthenticityNotGuaranteed
        case .unknownDevice:
            L10n.eventShieldReasonUnknownDevice
        case .unsignedDevice:
            L10n.eventShieldReasonUnsignedDevice
        case .unverifiedIdentity:
            L10n.eventShieldReasonUnverifiedIdentity
        case .previouslyVerified:
            L10n.eventShieldReasonPreviouslyVerified
        case .sentInClear:
            L10n.eventShieldReasonSentInClear
        }
    }
    
    var color: Color {
        switch self {
        case .notGuaranteed(let color),
             .unknownDevice(let color),
             .unsignedDevice(let color),
             .unverifiedIdentity(let color),
             .previouslyVerified(let color),
             .sentInClear(let color):
            color
        }
    }
    
    var icon: KeyPath<CompoundIcons, Image> {
        switch self {
        case .notGuaranteed: \.info
        case .unknownDevice, .unsignedDevice, .unverifiedIdentity, .previouslyVerified: \.helpSolid
        case .sentInClear: \.lockOff
        }
    }
}

extension EncryptionAuthenticity {
    init?(shieldState: ShieldState) {
        switch shieldState {
        case .red(let code, _):
            self.init(shieldStateCode: code, color: .red)
        case .grey(let code, _):
            self.init(shieldStateCode: code, color: .gray)
        case .none:
            return nil
        }
    }
    
    init(shieldStateCode: ShieldStateCode, color: EncryptionAuthenticity.Color) {
        switch shieldStateCode {
        case .authenticityNotGuaranteed:
            self = .notGuaranteed(color: color)
        case .unknownDevice:
            self = .unknownDevice(color: color)
        case .unsignedDevice:
            self = .unsignedDevice(color: color)
        case .unverifiedIdentity:
            self = .unverifiedIdentity(color: color)
        case .previouslyVerified:
            self = .previouslyVerified(color: color)
        case .sentInClear:
            self = .sentInClear(color: color)
        }
    }
}
