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
    var aliasLocalPart: String
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
    
    var availableAccessTypes: [CreateRoomAccessType] {
        var availableTypes = CreateRoomAccessType.allCases
        if isSpace || !isKnockingFeatureEnabled {
            availableTypes.removeAll { $0 == .askToJoin }
        }
        return availableTypes
    }
}

struct CreateRoomScreenViewStateBindings {
    var roomTopic: String
    var selectedAccessType: CreateRoomAccessType
    var showAttachmentConfirmationDialog = false
    
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
