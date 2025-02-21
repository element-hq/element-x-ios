//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

@MainActor
final class PillContext: ObservableObject {
    @Published var viewState: PillViewState = .undefined
    
    let data: PillTextAttachmentData
    var cancellable: AnyCancellable?
    
    init(timelineContext: TimelineViewModel.Context, data: PillTextAttachmentData) {
        self.data = data
        timelineContext.viewState.pillContextUpdater?(self)
    }
}

extension PillContext {
    enum MockType {
        case loadUser(isOwn: Bool)
        case loadedUser(isOwn: Bool)
        case loadingAlias
        case allUsers
    }
    
    static func mock(type: MockType) -> PillContext {
        let testID = "@test:test.com"
        let pillType: PillType
        switch type {
        case .loadUser(let isOwn):
            pillType = .user(userID: testID)
            let viewModel = PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = .mention(isOwnMention: isOwn, displayText: testID)
            Task {
                try? await Task.sleep(for: .seconds(2))
                viewModel.viewState = .mention(isOwnMention: isOwn, displayText: "@Test Long Display Text")
            }
            return viewModel
        case .loadedUser(let isOwn):
            pillType = .user(userID: "@test:test.com")
            let viewModel = PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = .mention(isOwnMention: isOwn, displayText: "@Very Very Long Test Display Text")
            return viewModel
        case .allUsers:
            pillType = .allUsers
            return PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
        case .loadingAlias:
            pillType = .roomAlias("#room-alias:matrix.org")
            return PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
        }
    }
}

enum PillViewState: Equatable {
    enum PillImage: Equatable {
        case link
        case roomAvatar(RoomAvatar)
    }
    
    case mention(isOwnMention: Bool, displayText: String)
    case reference(avatar: PillImage, displayText: String)
    case undefined
    
    var isOwnMention: Bool {
        switch self {
        case .mention(let isOwnMention, _):
            return isOwnMention
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .mention(_, let displayText), .reference(_, let displayText):
            return displayText
        case .undefined:
            return ""
        }
    }
    
    var isUndefined: Bool {
        switch self {
        case .undefined:
            return true
        default:
            return false
        }
    }
    
    var image: PillImage? {
        switch self {
        case .reference(let avatar, _):
            return avatar
        default:
            return nil
        }
    }
}
