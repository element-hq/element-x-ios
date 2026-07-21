//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SearchScreenViewModelAction {
    case presentRoom(roomID: String, eventID: String?)
    case cancel
}

enum SearchScreenMode: CaseIterable, Identifiable {
    case rooms
    case messages
    
    var id: Self {
        self
    }
    
    var title: String {
        switch self {
        case .rooms: UntranslatedL10n.screenSearchTabChats
        case .messages: UntranslatedL10n.screenSearchTabMessages
        }
    }
}

struct SearchScreenViewState: BindableState {
    var rooms = [SearchScreenRoom]()
    var messages = [SearchScreenMessage]()
    var isLoadingRooms = false
    var isLoadingMessages = false
    var bindings: SearchScreenViewStateBindings
    
    var isSearching: Bool {
        !bindings.searchQuery.isEmpty
    }
}

struct SearchScreenViewStateBindings {
    var searchQuery = ""
    var searchMode: SearchScreenMode = .rooms
}

enum SearchScreenViewAction {
    case appeared
    case selectRoom(roomID: String)
    case selectMessage(roomID: String, eventID: String)
    case reachedTop
    case reachedBottom
    case cancel
}

struct SearchScreenRoom: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let avatar: RoomAvatar
}

struct SearchScreenMessage: Identifiable, Equatable {
    let id: String
    let roomID: String
    let roomName: String
    let roomAvatar: RoomAvatar
    let senderName: String
    let content: TimelineEventContent
    let timestamp: Date
    
    init(_ result: SearchServiceResult, roomSummary: RoomSummary?, isOutgoing: Bool) {
        id = result.eventID
        roomID = result.roomID
        roomName = roomSummary?.name ?? result.roomID
        roomAvatar = roomSummary?.avatar ?? .room(id: result.roomID, name: roomSummary?.name, avatarURL: nil)
        senderName = isOutgoing ? L10n.commonYou : result.sender.disambiguatedDisplayName ?? result.sender.id
        content = result.content
        timestamp = result.timestamp
    }
    
    var preview: AttributedString? {
        guard let messageBody else { return nil }
        return AttributedString("\(senderName): ") + messageBody
    }
    
    private var messageBody: AttributedString? {
        switch content {
        case .message(let content):
            switch content {
            case .text(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .notice(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .emote(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .audio, .file, .image, .video:
                nil
            case .voice:
                AttributedString(L10n.commonVoiceMessage)
            case .location:
                AttributedString(L10n.commonSharedLocation)
            }
        case .poll(let question):
            AttributedString(question)
        case .liveLocation:
            AttributedString(L10n.commonSharedLiveLocation)
        case .redacted:
            AttributedString(L10n.commonMessageRemoved)
        }
    }
    
    var mediaPreview: SearchScreenMediaPreview? {
        guard case .message(let content) = content else { return nil }
        switch content {
        case .file(let content):
            return .init(title: content.caption ?? content.filename,
                         details: mediaDetails(filename: content.filename, fileSize: content.fileSize),
                         kind: .file)
        case .audio(let content):
            return .init(title: content.caption ?? content.filename,
                         details: mediaDetails(filename: content.filename, fileSize: content.fileSize),
                         kind: .audio)
        case .image(let content):
            return .init(title: content.caption ?? content.filename,
                         details: mediaDetails(filename: content.filename, fileSize: content.imageInfo.fileSize),
                         kind: .image(thumbnail: content.thumbnailInfo ?? content.imageInfo, blurhash: content.blurhash))
        case .video(let content):
            return .init(title: content.caption ?? content.filename,
                         details: mediaDetails(filename: content.filename, fileSize: content.videoInfo.fileSize),
                         kind: .video(thumbnail: content.thumbnailInfo, blurhash: content.blurhash))
        case .text, .notice, .emote, .voice, .location:
            return nil
        }
    }
    
    private func mediaDetails(filename: String, fileSize: UInt?) -> String {
        var details = filename.validatedFileExtension.uppercased()
        if let fileSize {
            details += " (\(fileSize.formatted(.byteCount(style: .file))))"
        }
        return details
    }
}

struct SearchScreenMediaPreview: Equatable {
    enum Kind: Equatable {
        case file
        case audio
        case image(thumbnail: ImageInfoProxy?, blurhash: String?)
        case video(thumbnail: ImageInfoProxy?, blurhash: String?)
    }
    
    let title: String
    let details: String
    let kind: Kind
}
