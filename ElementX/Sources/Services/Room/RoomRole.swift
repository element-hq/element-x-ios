//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

enum RoomRole: Comparable {
    /// Default role PL 0...49
    case user
    /// Able to perform room moderation actions PL 50...99
    case moderator
    /// Able to edit room settings and perform any action aside from room upgrading PL 100...149
    case administrator
    /// Same power of an admin, but they can also upgrade the room, PL 150 onwards
    case owner
    /// Creator of the room, PL infinite
    case creator
}

extension RoomRole {
    init(powerLevel: RoomPowerLevel) {
        do {
            let role = try suggestedRoleForPowerLevel(powerLevel: powerLevel.rustPowerLevel)
            self.init(role, powerLevel: powerLevel)
        } catch {
            MXLog.error("Failled to get suggested role for power level \(powerLevel): \(error)")
            self = .user
        }
    }
    
    init(_ role: RoomMemberRole, powerLevel: RoomPowerLevel) {
        switch role {
        case .creator:
            self = .creator
        case .administrator:
            switch powerLevel {
            case .value(let value):
                self = value >= 150 ? .owner : .administrator
            default:
                fatalError("Impossible")
            }
        case .moderator:
            self = .moderator
        case .user:
            self = .user
        }
    }
        
    var isAdminOrHigher: Bool {
        switch self {
        case .administrator, .creator, .owner:
            return true
        case .moderator, .user:
            return false
        }
    }
    
    var isOwner: Bool {
        switch self {
        case .creator, .owner:
            return true
        case .administrator, .moderator, .user:
            return false
        }
    }
}

extension RoomRole {
    init(powerLevelValue: Int64) {
        // Also this is not great, and should be handled by a `suggestedRoleForPowerLevelValue` function from the SDK
        guard powerLevelValue < 150 else {
            self = .owner
            return
        }
        
        do {
            switch try suggestedRoleForPowerLevel(powerLevel: .value(value: powerLevelValue)) {
            case .administrator:
                self = .administrator
            case .creator:
                fatalError("Impossible")
            case .moderator:
                self = .moderator
            case .user:
                self = .user
            }
        } catch {
            MXLog.error("Falied to convert power level value to role: \(error)")
            self = .user
        }
    }
    
    var rustRole: RoomMemberRole {
        switch self {
        case .creator:
            .creator
        case .administrator, .owner:
            .administrator
        case .moderator:
            .moderator
        case .user:
            .user
        }
    }
    
    /// To be used when setting the power level of a user to get the suggested equivalent power level value for that specific role
    /// NOTE: Do not use for comparison, use the true power level instead.
    var powerLevelValue: Int64 {
        switch powerLevel {
        case .infinite:
            fatalError("Impossible")
        case .value(let value):
            return Int64(value)
        }
    }
    
    var powerLevel: RoomPowerLevel {
        guard self != .owner else {
            // Would be better if the SDK would return this, maybe a `suggestedPowerLevelValueForRole` function would solve the problem
            return .value(150)
        }
        
        do {
            return try RoomPowerLevel(rustPowerLevel: suggestedPowerLevelForRole(role: rustRole))
        } catch {
            MXLog.error("Falied to convert role to power level value: \(error)")
            return .value(0)
        }
    }
}
