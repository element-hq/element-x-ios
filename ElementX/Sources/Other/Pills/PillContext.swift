//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

@MainActor
final class PillContext: ObservableObject {
    struct PillViewState: Equatable {
        let isOwnMention: Bool
        let displayText: String
    }
    
    @Published private(set) var viewState: PillViewState
    
    private var cancellable: AnyCancellable?
    
    init(timelineContext: TimelineViewModel.Context, data: PillTextAttachmentData) {
        switch data.type {
        case let .user(id):
            let isOwnMention = id == timelineContext.viewState.ownUserID
            if let profile = timelineContext.viewState.members[id] {
                var name = id
                if let displayName = profile.displayName {
                    name = "@\(displayName)"
                }
                viewState = PillViewState(isOwnMention: isOwnMention, displayText: name)
            } else {
                viewState = PillViewState(isOwnMention: isOwnMention, displayText: id)
                cancellable = timelineContext.$viewState.sink { [weak self] viewState in
                    guard let self else {
                        return
                    }
                    if let profile = viewState.members[id] {
                        var name = id
                        if let displayName = profile.displayName {
                            name = "@\(displayName)"
                        }
                        self.viewState = PillViewState(isOwnMention: isOwnMention, displayText: name)
                        cancellable = nil
                    }
                }
            }
        case .allUsers:
            viewState = PillViewState(isOwnMention: true, displayText: PillConstants.atRoom)
        }
    }
}

extension PillContext {
    enum MockType {
        case loadUser(isOwn: Bool)
        case loadedUser(isOwn: Bool)
        case allUsers
    }
    
    static func mock(type: MockType) -> PillContext {
        let testID = "@test:test.com"
        let pillType: PillType
        switch type {
        case .loadUser(let isOwn):
            pillType = .user(userID: testID)
            let viewModel = PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = PillViewState(isOwnMention: isOwn, displayText: testID)
            Task {
                try? await Task.sleep(for: .seconds(2))
                viewModel.viewState = PillViewState(isOwnMention: isOwn, displayText: "@Test Long Display Text")
            }
            return viewModel
        case .loadedUser(let isOwn):
            pillType = .user(userID: "@test:test.com")
            let viewModel = PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = PillViewState(isOwnMention: isOwn, displayText: "@Very Very Long Test Display Text")
            return viewModel
        case .allUsers:
            pillType = .allUsers
            return PillContext(timelineContext: TimelineViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
        }
    }
}
