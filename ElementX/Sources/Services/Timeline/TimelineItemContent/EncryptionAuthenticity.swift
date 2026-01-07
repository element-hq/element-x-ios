//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

/// Represents an issue with a timeline item's authenticity such as coming from an
/// unsigned session or being sent unencrypted in an encrypted room. See Rust's
/// `ShieldStateCode` for more information about the meaning of the cases.
enum EncryptionAuthenticity: Hashable {
    enum Color { case red, gray }
    
    case notGuaranteed(color: Color)
    case unknownDevice(color: Color)
    case unsignedDevice(color: Color)
    case unverifiedIdentity(color: Color)
    case verificationViolation(color: Color)
    case sentInClear(color: Color)
    case mismatchedSender(color: Color)
    
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
        case .verificationViolation:
            L10n.eventShieldReasonPreviouslyVerified
        case .sentInClear:
            L10n.eventShieldReasonSentInClear
        case .mismatchedSender:
            L10n.eventShieldMismatchedSender
        }
    }
    
    var color: Color {
        switch self {
        case .notGuaranteed(let color),
             .unknownDevice(let color),
             .unsignedDevice(let color),
             .unverifiedIdentity(let color),
             .verificationViolation(let color),
             .sentInClear(let color),
             .mismatchedSender(let color):
            color
        }
    }
    
    var icon: KeyPath<CompoundIcons, Image> {
        switch self {
        case .notGuaranteed: \.info
        case .unknownDevice, .unsignedDevice, .unverifiedIdentity, .verificationViolation, .mismatchedSender: \.helpSolid
        case .sentInClear: \.lockOff
        }
    }
}

extension EncryptionAuthenticity {
    init?(shieldState: ShieldState) {
        switch shieldState {
        case .red(let code):
            self.init(shieldStateCode: code, color: .red)
        case .grey(let code):
            self.init(shieldStateCode: code, color: .gray)
        case .none:
            return nil
        }
    }
    
    init(shieldStateCode: TimelineEventShieldStateCode, color: EncryptionAuthenticity.Color) {
        switch shieldStateCode {
        case .authenticityNotGuaranteed:
            self = .notGuaranteed(color: color)
        case .unknownDevice:
            self = .unknownDevice(color: color)
        case .unsignedDevice:
            self = .unsignedDevice(color: color)
        case .unverifiedIdentity:
            self = .unverifiedIdentity(color: color)
        case .verificationViolation:
            self = .verificationViolation(color: color)
        case .sentInClear:
            self = .sentInClear(color: color)
        case .mismatchedSender:
            self = .mismatchedSender(color: color)
        }
    }
}
