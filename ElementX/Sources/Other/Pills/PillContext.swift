//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
