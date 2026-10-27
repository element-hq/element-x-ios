//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// Everything needed to create a room or space, use ``room(name:topic:accessType:userIDs:avatarURL:aliasLocalPart:)``,
/// ``space(name:topic:accessType:avatarURL:aliasLocalPart:)`` or ``directRoom(userID:)`` for sensible defaults.
struct CreateRoomParameters: Equatable {
    var name: String?
    var topic: String?
    var isEncrypted: Bool
    var isDirect: Bool
    var visibility: RoomVisibility
    var preset: RoomPreset
    var userIDs: [String]
    var avatarURL: URL?
    var powerLevelContentOverride: PowerLevels?
    var joinRuleOverride: JoinRule?
    var historyVisibilityOverride: RoomHistoryVisibility?
    var aliasLocalPart: String?
    var isSpace: Bool
    
    var rustValue: MatrixRustSDK.CreateRoomParameters {
        .init(name: name,
              topic: topic,
              isEncrypted: isEncrypted,
              isDirect: isDirect,
              visibility: visibility,
              preset: preset,
              invite: userIDs,
              avatar: avatarURL?.absoluteString,
              powerLevelContentOverride: powerLevelContentOverride,
              joinRuleOverride: joinRuleOverride?.rustValue,
              historyVisibilityOverride: historyVisibilityOverride,
              // This is an FFI naming mistake, what is required is the `aliasLocalPart` not the whole alias
              canonicalAlias: aliasLocalPart,
              isSpace: isSpace)
    }
}

extension CreateRoomParameters {
    static func directRoom(userID: String) -> CreateRoomParameters {
        CreateRoomParameters(name: nil,
                             topic: nil,
                             isEncrypted: true,
                             isDirect: true,
                             visibility: .private,
                             preset: .trustedPrivateChat,
                             userIDs: [userID],
                             avatarURL: nil,
                             powerLevelContentOverride: roomCreationPowerLevelOverrides,
                             joinRuleOverride: nil,
                             historyVisibilityOverride: .invited,
                             aliasLocalPart: nil,
                             isSpace: false)
    }
    
    static func room(name: String?,
                     topic: String?,
                     accessType: CreateRoomAccessType,
                     userIDs: [String] = [],
                     avatarURL: URL?,
                     aliasLocalPart: String?) -> CreateRoomParameters {
        CreateRoomParameters(name: name,
                             topic: topic,
                             isEncrypted: accessType.isEncrypted,
                             isDirect: false,
                             visibility: accessType.visibility,
                             preset: accessType.preset,
                             userIDs: userIDs,
                             avatarURL: avatarURL,
                             powerLevelContentOverride: accessType.isAskToJoin ? knockingRoomCreationPowerLevelOverrides : roomCreationPowerLevelOverrides,
                             joinRuleOverride: accessType.joinRuleOverride,
                             historyVisibilityOverride: accessType.historyVisibilityOverride,
                             aliasLocalPart: aliasLocalPart,
                             isSpace: false)
    }
    
    static func space(name: String?,
                      topic: String?,
                      accessType: CreateRoomAccessType,
                      avatarURL: URL?,
                      aliasLocalPart: String?) -> CreateRoomParameters {
        CreateRoomParameters(name: name,
                             topic: topic,
                             isEncrypted: accessType.isEncrypted,
                             isDirect: false,
                             visibility: accessType.visibility,
                             preset: accessType.preset,
                             userIDs: [],
                             avatarURL: avatarURL,
                             powerLevelContentOverride: accessType == .public ? publicSpaceCreationPowerLevelOverrides : standardSpaceCreationPowerLevelOverrides,
                             joinRuleOverride: accessType.joinRuleOverride,
                             historyVisibilityOverride: accessType.historyVisibilityOverride,
                             aliasLocalPart: aliasLocalPart,
                             isSpace: true)
    }
    
    private static var roomCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: nil,
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: Int32(0),
              notifications: nil,
              users: [:],
              events: [
                  "m.call.member": Int32(0),
                  "org.matrix.msc3401.call.member": Int32(0)
              ])
    }
    
    private static var knockingRoomCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: nil,
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: Int32(50),
              notifications: nil,
              users: [:],
              events: [
                  "m.call.member": Int32(0),
                  "org.matrix.msc3401.call.member": Int32(0)
              ])
    }
    
    private static var standardSpaceCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: Int32(100),
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: Int32(50),
              notifications: nil,
              users: [:],
              events: [:])
    }
    
    private static var publicSpaceCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: Int32(100),
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: Int32(0),
              notifications: nil,
              users: [:],
              events: [:])
    }
}

private extension CreateRoomAccessType {
    var isEncrypted: Bool {
        switch self {
        case .public:
            false
        default:
            true
        }
    }
    
    var visibility: RoomVisibility {
        isVisibilityPrivate ? .private : .public
    }
    
    var preset: RoomPreset {
        isVisibilityPrivate ? .privateChat : .publicChat
    }
    
    var historyVisibilityOverride: RoomHistoryVisibility? {
        isVisibilityPrivate ? .invited : nil
    }
    
    var joinRuleOverride: JoinRule? {
        switch self {
        case .askToJoin:
            .knock
        case .spaceMembers(let spaceID):
            .restricted(rules: [.roomMembership(roomID: spaceID)])
        case .askToJoinWithSpaceMembers(let spaceID):
            .knockRestricted(rules: [.roomMembership(roomID: spaceID)])
        case .private, .public:
            nil
        }
    }
    
    var isAskToJoin: Bool {
        switch self {
        case .askToJoin, .askToJoinWithSpaceMembers:
            true
        default:
            false
        }
    }
}
