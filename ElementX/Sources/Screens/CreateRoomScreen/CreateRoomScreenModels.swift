//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum CreateRoomScreenErrorType: Error {
    case failedCreatingRoom
    case failedProcessingMedia
    case failedUploadingMedia
    case fileTooLarge
    case mediaFileError
    case unknown
}

enum CreateRoomScreenViewModelAction {
    case createdRoom(JoinedRoomProxyProtocol, SpaceRoomListProxyProtocol?)
    case displayMediaPicker
    case displayCameraPicker
    case dismiss
}

struct CreateRoomScreenViewState: BindableState {
    let isSpace: Bool
    let shouldShowCancelButton: Bool
    var roomName: String
    let serverName: String
    let isKnockingFeatureEnabled: Bool
    let canSelectSpace: Bool
    var aliasLocalPart: String
    var editableSpaces: [SpaceServiceRoom] = []
    var bindings: CreateRoomScreenViewStateBindings
    var avatarMediaInfo: MediaInfo? {
        didSet {
            switch avatarMediaInfo {
            case .image(_, let thumbnailURL, _):
                avatarImage = UIImage(contentsOfFile: thumbnailURL.path(percentEncoded: false))
            default:
                avatarImage = nil
            }
        }
    }
    
    var avatarImage: UIImage?
    
    var canCreateRoom: Bool {
        !roomName.isEmpty && aliasErrors.isEmpty
    }

    var aliasErrors: Set<CreateRoomScreenAliasErrorState> = []
    var aliasErrorDescription: String? {
        if aliasErrors.contains(.alreadyExists) {
            L10n.errorRoomAddressAlreadyExists
        } else if aliasErrors.contains(.invalidSymbols) {
            L10n.errorRoomAddressInvalidSymbols
        } else {
            nil
        }
    }
        
    var availableAccessTypes: [CreateRoomScreenAccessType] {
        var availableAccessTypes: [CreateRoomScreenAccessType] = []
        if isSpace {
            availableAccessTypes = [.public]
        } else if let selectedSpace = bindings.selectedSpace, selectedSpace.joinRule != .public {
            availableAccessTypes = [.spaceMembers]
            if isKnockingFeatureEnabled {
                availableAccessTypes.append(.askToJoinWithSpaceMembers)
            }
        } else {
            availableAccessTypes = [.public]
            if isKnockingFeatureEnabled {
                availableAccessTypes.append(.askToJoin)
            }
        }
        availableAccessTypes.append(.private)
        return availableAccessTypes
    }
    
    var roomAccessType: CreateRoomAccessType {
        switch bindings.selectedAccessType {
        case .public:
            return .public
        case .spaceMembers:
            return .spaceMembers(spaceID: bindings.selectedSpace?.id ?? "")
        case .askToJoinWithSpaceMembers:
            return .askToJoinWithSpaceMembers(spaceID: bindings.selectedSpace?.id ?? "")
        case .askToJoin:
            return .askToJoin
        case .private:
            return .private
        }
    }
}

struct CreateRoomScreenViewStateBindings {
    var roomTopic: String
    var selectedAccessType: CreateRoomScreenAccessType
    var selectedSpace: SpaceServiceRoom?
    
    var showAttachmentConfirmationDialog = false
    var showSpaceSelectionSheet = false
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<CreateRoomScreenErrorType>?
}

enum CreateRoomScreenViewAction {
    case dismiss
    case createRoom
    case displayCameraPicker
    case displayMediaPicker
    case removeImage
    case updateRoomName(String)
    case updateAliasLocalPart(String)
}

enum CreateRoomScreenAliasErrorState {
    case alreadyExists
    case invalidSymbols
}

extension Set<CreateRoomScreenAliasErrorState> {
    var errorDescription: String? {
        if contains(.alreadyExists) {
            return L10n.errorRoomAddressAlreadyExists
        } else if contains(.invalidSymbols) {
            return L10n.errorRoomAddressInvalidSymbols
        }
        return nil
    }
}

enum CreateRoomScreenAccessType {
    case `public`
    case spaceMembers
    case askToJoinWithSpaceMembers
    case askToJoin
    case `private`
}

enum CreateRoomScreenSpaceSelectionMode {
    case editableSpacesList(preSelectedSpace: SpaceServiceRoom?)
    case none
}
