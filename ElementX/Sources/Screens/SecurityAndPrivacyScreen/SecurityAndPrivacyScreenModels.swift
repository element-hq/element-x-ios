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
    let serverName: String
    
    var currentSettings: SecurityAndPrivacySettings
    var bindings: SecurityAndPrivacyScreenViewStateBindings
    let strings: SecurityAndPrivacyScreenStrings
    
    var canonicalAlias: String?
    var isKnockingEnabled: Bool
    var isSpaceSettingsEnabled: Bool
    var isSpace: Bool
    
    var canEditAddress = false
    var canEditJoinRule = false
    var canEnableEncryption = false
    var canEditHistoryVisibility = false
    
    /// The union of joined parent spaces and the joined spaces in the current access type
    var selectableJoinedSpaces: [SpaceServiceRoomProtocol] = []
    
    /// The count of the intersection between the set of joined parent spaces and the set of spaces in the current access type
    var selectableSpacesCount: Int {
        Set(selectableJoinedSpaces.map(\.id) + currentSettings.accessType.spaceIDs).count
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
        var options = [SecurityAndPrivacyHistoryVisibility.shared]
        if !bindings.desiredSettings.isEncryptionEnabled, bindings.desiredSettings.accessType == .anyone {
            options.append(.worldReadable)
        } else {
            options.append(.invited)
        }
        return options.sorted()
    }
    
    var isSpaceMembersOptionAvailable: Bool {
        currentSettings.accessType.isSpaceMembers || isSpaceMembersOptionSelectable
    }
    
    var isSpaceMembersOptionSelectable: Bool {
        isSpaceSettingsEnabled && selectableSpacesCount > 0
    }
    
    var isAskToJoinWithSpaceMembersOptionAvailable: Bool {
        currentSettings.accessType.isAskToJoinWithSpaceMembers || isAskToJoinWithSpaceMembersOptionSelectable
    }
    
    var isAskToJoinWithSpaceMembersOptionSelectable: Bool {
        isSpaceMembersOptionSelectable && isKnockingEnabled
    }
    
    var spaceMembersDescription: String {
        if isSpaceMembersOptionSelectable {
            switch spaceSelection {
            case .singleJoined(let joinedSpace):
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionSingleParentDescription(joinedSpace.name)
            case .singleUnknown(let id):
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionSingleParentDescription(id)
            case .multiple, .empty:
                L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionMultipleParentsDescription
            }
        } else {
            L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionUnavailableDescription
        }
    }
    
    var askToJoinWithSpaceMembersDescription: String {
        if isAskToJoinWithSpaceMembersOptionSelectable {
            switch spaceSelection {
            case .singleJoined(let joinedSpace):
                L10n.screenSecurityAndPrivacyAskToJoinSingleSpaceMembersOptionDescription(joinedSpace.name)
            case .singleUnknown(let id):
                L10n.screenSecurityAndPrivacyAskToJoinSingleSpaceMembersOptionDescription(id)
            case .multiple, .empty:
                L10n.screenSecurityAndPrivacyAskToJoinMultipleSpacesMembersOptionDescription
            }
        } else {
            L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionUnavailableDescription
        }
    }
    
    var shouldShowAccessSectionFooter: Bool {
        if (bindings.desiredSettings.accessType.isSpaceMembers && isSpaceMembersOptionSelectable) ||
            (bindings.desiredSettings.accessType.isAskToJoinWithSpaceMembers && isAskToJoinWithSpaceMembersOptionSelectable),
            case .multiple = spaceSelection {
            return true
        }
        
        return false
    }
    
    enum SpaceSelection {
        /// There is only one available parent space for selection and is joined by the user
        case singleJoined(SpaceServiceRoomProtocol)
        /// There is only one available space for selection and is unknown to the user
        case singleUnknown(id: String)
        /// Multiple spaces are available for selection
        case multiple
        /// Edge case where the space members access type was found but it did not contain any space
        case empty
    }
    
    var spaceSelection: SpaceSelection {
        if selectableSpacesCount == 0 {
            .empty
        } else if selectableSpacesCount > 1 {
            .multiple
        } else if let joinedSpace = selectableJoinedSpaces.first {
            if currentSettings.accessType.isSpaceMembers || currentSettings.accessType.isAskToJoinWithSpaceMembers {
                if currentSettings.accessType.spaceIDs.isEmpty {
                    // Edge case where the access type is already space members, but it does not contain any id
                    // So if the user wants to add their own parent they need to do it from the selection menu
                    .multiple
                } else {
                    .singleJoined(joinedSpace)
                }
            } else {
                .singleJoined(joinedSpace)
            }
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
         isSpaceSettingsEnabled: Bool,
         historySharingDetailsURL: URL) {
        self.serverName = serverName
        self.isKnockingEnabled = isKnockingEnabled
        self.isSpace = isSpace
        self.isSpaceSettingsEnabled = isSpaceSettingsEnabled
        
        let settings = SecurityAndPrivacySettings(accessType: accessType,
                                                  isEncryptionEnabled: isEncryptionEnabled,
                                                  historyVisibility: historyVisibility)
        currentSettings = settings
        bindings = SecurityAndPrivacyScreenViewStateBindings(desiredSettings: settings)
        strings = SecurityAndPrivacyScreenStrings(historySharingDetailsURL: historySharingDetailsURL)
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
    case askToJoinWithSpaceMembers(spaceIDs: [String])
    case anyone
    case spaceMembers(spaceIDs: [String])
    
    var isSpaceMembers: Bool {
        switch self {
        case .spaceMembers:
            true
        default:
            false
        }
    }
    
    var isAskToJoinWithSpaceMembers: Bool {
        switch self {
        case .askToJoinWithSpaceMembers:
            true
        default:
            false
        }
    }
    
    var isAddressRequired: Bool {
        switch self {
        case .inviteOnly, .spaceMembers:
            false
        case .anyone, .askToJoin, .askToJoinWithSpaceMembers:
            true
        }
    }
    
    var spaceIDs: [String] {
        switch self {
        case .spaceMembers(let spaceIDs), .askToJoinWithSpaceMembers(let spaceIDs):
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
    case selectedAskToJoinWithSpaceMembersAccess
    case manageSpaces
}

enum SecurityAndPrivacyHistoryVisibility: Int, Comparable {
    case invited
    case shared
    case worldReadable
    
    var fallbackOption: Self {
        switch self {
        case .invited, .shared:
            return .shared
        case .worldReadable:
            return .invited
        }
    }
    
    static func < (lhs: SecurityAndPrivacyHistoryVisibility, rhs: SecurityAndPrivacyHistoryVisibility) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SecurityAndPrivacyScreenStrings {
    let accessSectionFooterString: AttributedString
    let historySectionFooterString: AttributedString
    
    init(historySharingDetailsURL: URL) {
        let linkPlaceholder = "{link}"
        
        var accessFooterString = AttributedString(L10n.screenSecurityAndPrivacyRoomAccessFooter(linkPlaceholder))
        var accessLinkString = AttributedString(L10n.screenSecurityAndPrivacyRoomAccessFooterManageSpacesAction)
        accessLinkString.link = .init(stringLiteral: "action://manageSpace") // The link address doesn't matter
        accessLinkString.bold()
        accessFooterString.replace(linkPlaceholder, with: accessLinkString)
        accessSectionFooterString = accessFooterString
        
        var historyFooterString = AttributedString(L10n.screenSecurityAndPrivacyRoomHistorySectionFooter(linkPlaceholder))
        var historyLinkString = AttributedString(L10n.actionLearnMore)
        historyLinkString.link = historySharingDetailsURL
        historyLinkString.bold()
        historyFooterString.replace(linkPlaceholder, with: historyLinkString)
        historySectionFooterString = historyFooterString
    }
}
