//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum SpaceAddRoomsScreenViewModelAction {
    case dismiss
}

struct SpaceAddRoomsScreenViewState: BindableState {
    var roomsSection: Section
    var selectedRooms: [SpaceAddRoomsScreenRoom] = []
    
    var bindings = SpaceAddRoomsScreenViewStateBindings()
    
    struct Section {
        enum SectionType: Equatable { case searchResults, suggestions }
        let type: SectionType
        
        let rooms: [SpaceAddRoomsScreenRoom]
        
        var title: String? {
            switch type {
            case .searchResults:
                return nil
            case .suggestions:
                return rooms.isEmpty ? nil : L10n.commonSuggestions
            }
        }
    }
}

struct SpaceAddRoomsScreenViewStateBindings {
    var searchQuery = ""
    var selectedRoomsPosition: String?
}

enum SpaceAddRoomsScreenViewAction {
    case cancel
    case reachedTop
    case reachedBottom
    case searchQueryChanged
    case toggleRoom(SpaceAddRoomsScreenRoom)
    case save
}

struct SpaceAddRoomsScreenRoom: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let avatar: RoomAvatar
}

extension SpaceAddRoomsScreenRoom {
    init(summary: RoomSummary) {
        self.init(id: summary.id,
                  title: summary.name,
                  description: summary.roomListDescription,
                  avatar: summary.avatar)
    }
    
    init(roomProxy: JoinedRoomProxyProtocol) {
        self.init(id: roomProxy.id,
                  title: roomProxy.infoPublisher.value.displayName ?? roomProxy.id,
                  description: roomProxy.infoPublisher.value.roomListDescription,
                  avatar: roomProxy.infoPublisher.value.avatar)
    }
}

private extension RoomInfoProxyProtocol {
    var roomListDescription: String {
        if isDirect {
            return canonicalAlias ?? ""
        }
        
        if let alias = canonicalAlias {
            return alias
        }
        
        guard heroes.count > 0 else {
            return ""
        }
        
        var heroComponents = heroes.compactMap(\.displayName)
        
        let othersCount = Int(activeMembersCount) - heroes.count
        if othersCount > 0 {
            heroComponents.append(L10n.commonManyMembers(othersCount))
        }
        
        return heroComponents.formatted(.list(type: .and))
    }
}
