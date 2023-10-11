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
        let contentID: String
        let isOwnMention: Bool
        let name: String?
        let displayText: String
        let avatarURL: URL?
    }
    
    @Published private(set) var viewState: PillViewState
    
    private var cancellable: AnyCancellable?
    
    init(roomContext: RoomScreenViewModel.Context, data: PillTextAttachmentData) {
        switch data.type {
        case let .user(id):
            let isOwnMention = id == roomContext.viewState.ownUserID
            if let profile = roomContext.viewState.members[id] {
                let name = profile.displayName ?? id
                viewState = PillViewState(contentID: id, isOwnMention: isOwnMention, name: name, displayText: name, avatarURL: profile.avatarURL)
            } else {
                viewState = PillViewState(contentID: id, isOwnMention: isOwnMention, name: nil, displayText: id, avatarURL: nil)
                cancellable = roomContext.$viewState.sink { [weak self] viewState in
                    guard let self else {
                        return
                    }
                    if let profile = viewState.members[id] {
                        let name = profile.displayName ?? id
                        self.viewState = PillViewState(contentID: id, isOwnMention: isOwnMention, name: name, displayText: name, avatarURL: profile.avatarURL)
                        cancellable = nil
                    }
                }
            }
        case .allUsers:
            viewState = PillViewState(contentID: roomContext.viewState.roomID, isOwnMention: true, name: roomContext.viewState.roomTitle, displayText: PillConstants.atRoom, avatarURL: roomContext.viewState.roomAvatarURL)
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
            let viewModel = PillContext(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = PillViewState(contentID: testID, isOwnMention: isOwn, name: nil, displayText: testID, avatarURL: nil)
            Task {
                try? await Task.sleep(for: .seconds(2))
                viewModel.viewState = PillViewState(contentID: "@test:test.com", isOwnMention: isOwn, name: nil, displayText: "Test Long Display Text", avatarURL: URL.documentsDirectory)
            }
            return viewModel
        case .loadedUser(let isOwn):
            pillType = .user(userID: "@test:test.com")
            let viewModel = PillContext(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.viewState = PillViewState(contentID: "@test:test.com", isOwnMention: isOwn, name: nil, displayText: "Very Very Long Test Display Text", avatarURL: URL.documentsDirectory)
            return viewModel
        case .allUsers:
            pillType = .allUsers
            return PillContext(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
        }
    }
}
