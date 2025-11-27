//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SecurityAndPrivacyScreenViewModelAction {
    case displayEditAddressScreen
    case dismiss
    case displayManageAuthorizedSpacesScreen(AuthorizedSpacesSelection)
}

struct SecurityAndPrivacyScreenViewState: BindableState {
    private static let accessSectionFooterAttributedString = {
        let linkPlaceholder = "{link}"
        var footer = AttributedString(L10n.screenSecurityAndPrivacyRoomAccessFooter(linkPlaceholder))
        var linkString = AttributedString(L10n.screenSecurityAndPrivacyRoomAccessFooterManageSpacesAction)
        // Doesn't really matter
        linkString.link = .init(stringLiteral: "action://manageSpace")
        linkString.bold()
        footer.replace(linkPlaceholder, with: linkString)
        return footer
    }()
    
    let serverName: String
    var currentSettings: SecurityAndPrivacySettings
    var bindings: SecurityAndPrivacyScreenViewStateBindings
    var canonicalAlias: String?
    var isKnockingEnabled: Bool
    var isSpaceSettingsEnabled: Bool
    var isSpace: Bool
    
    var canEditAddress = false
    var canEditJoinRule = false
    var canEnableEncryption = false
    var canEditHistoryVisibility = false
    var joinedParentSpaces: [SpaceRoomProxyProtocol] = []
    
    /// The count of the intersection between the set of joined parent spaces and the set of spaces in the current access type
    var selectableSpacesCount: Int {
        Set(joinedParentSpaces.map(\.id) + currentSettings.accessType.spaceIDs).count
    }
    
    private var hasChanges: Bool {
        currentSettings != bindings.desiredSettings
    }
    
    var isSaveDisabled: Bool {
        !hasChanges ||
            (currentSettings.isVisibileInRoomDirectory == nil &&
                bindings.desiredSettings.accessType != .inviteOnly &&
                canonicalAlias != nil)
    }
    
    var availableVisibilityOptions: [SecurityAndPrivacyHistoryVisibility] {
        var options = [SecurityAndPrivacyHistoryVisibility.sinceSelection]
        if !bindings.desiredSettings.isEncryptionEnabled, bindings.desiredSettings.accessType == .anyone {
            options.append(.anyone)
        } else {
            options.append(.sinceInvite)
        }
        return options
    }
    
    var isSpaceMembersOptionAvailable: Bool {
        currentSettings.accessType.isSpaceUsers || isSpaceMembersOptionSelectable
    }
    
    var isSpaceMembersOptionSelectable: Bool {
        isSpaceSettingsEnabled && selectableSpacesCount > 0
    }
    
    var spaceMembersDescription: String {
        if isSpaceMembersOptionSelectable {
            switch spaceSelection {
            case .singleJoined(let joinedParentSpace):
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionSingleParentDescription(joinedParentSpace.name)
            case .singleUnknown(let id):
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionSingleParentDescription(id)
            case .multiple:
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionMultipleParentsDescription
            }
        } else {
            L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionUnavailableDescription
        }
    }
    
    var accessSectionFooter: AttributedString? {
        if bindings.desiredSettings.accessType.isSpaceUsers, isSpaceMembersOptionSelectable, selectableSpacesCount > 1 {
            Self.accessSectionFooterAttributedString
        } else {
            nil
        }
    }
    
    enum SpaceSelection {
        /// There is only one available parent space for selection and is joined by the user
        case singleJoined(SpaceRoomProxyProtocol)
        /// There is only one available space for selection and is unknown to the user
        case singleUnknown(id: String)
        /// Multiple spaces are available for selection
        case multiple
    }
    
    var spaceSelection: SpaceSelection {
        if selectableSpacesCount > 1 {
            .multiple
        } else if let joinedParent = joinedParentSpaces.first {
            .singleJoined(joinedParent)
        } else if let unknownSpaceID = currentSettings.accessType.spaceIDs.first {
            // The space is not joined by the user but is currently selected
            .singleUnknown(id: unknownSpaceID)
        } else {
            // Not reachable because it would mean the selectable spaces are more than 1
            // but are neither selected and/or joined parents.
            fatalError("Not reachable")
        }
    }
        
    init(serverName: String,
         accessType: SecurityAndPrivacyRoomAccessType,
         isEncryptionEnabled: Bool,
         historyVisibility: SecurityAndPrivacyHistoryVisibility,
         isSpace: Bool,
         isKnockingEnabled: Bool,
         isSpaceSettingsEnabled: Bool) {
        self.serverName = serverName
        self.isKnockingEnabled = isKnockingEnabled
        self.isSpace = isSpace
        self.isSpaceSettingsEnabled = isSpaceSettingsEnabled
        
        let settings = SecurityAndPrivacySettings(accessType: accessType,
                                                  isEncryptionEnabled: isEncryptionEnabled,
                                                  historyVisibility: historyVisibility)
        currentSettings = settings
        bindings = SecurityAndPrivacyScreenViewStateBindings(desiredSettings: settings)
    }
}

struct SecurityAndPrivacyScreenViewStateBindings {
    var desiredSettings: SecurityAndPrivacySettings
    var alertInfo: AlertInfo<SecurityAndPrivacyAlertType>?
}

struct SecurityAndPrivacySettings: Equatable {
    var accessType: SecurityAndPrivacyRoomAccessType
    var isEncryptionEnabled: Bool
    var historyVisibility: SecurityAndPrivacyHistoryVisibility
    var isVisibileInRoomDirectory: Bool?
}

enum SecurityAndPrivacyRoomAccessType: Equatable {
    case inviteOnly
    case askToJoin
    case askToJoinWithSpaceUsers(spaceIDs: [String])
    case anyone
    case spaceUsers(spaceIDs: [String])
    
    var isSpaceUsers: Bool {
        switch self {
        case .spaceUsers:
            true
        default:
            false
        }
    }
    
    var isAddressRequired: Bool {
        switch self {
        case .inviteOnly, .spaceUsers:
            false
        case .anyone, .askToJoin, .askToJoinWithSpaceUsers:
            true
        }
    }
    
    var spaceIDs: [String] {
        switch self {
        case .spaceUsers(let spaceIDs), .askToJoinWithSpaceUsers(let spaceIDs):
            return spaceIDs
        case .inviteOnly, .askToJoin, .anyone:
            return []
        }
    }
}

enum SecurityAndPrivacyAlertType {
    case enableEncryption
    case unsavedChanges
}

enum SecurityAndPrivacyScreenViewAction {
    case cancel
    case save
    case tryUpdatingEncryption(Bool)
    case editAddress
    case selectedSpaceMembersAccess
    case manageSpaces
}

enum SecurityAndPrivacyHistoryVisibility {
    case sinceSelection
    case sinceInvite
    case anyone
    
    var fallbackOption: Self {
        switch self {
        case .sinceInvite, .sinceSelection:
            return .sinceSelection
        case .anyone:
            return .sinceInvite
        }
    }
}
