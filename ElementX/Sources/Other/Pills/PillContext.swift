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
    enum PillViewState {
        case loading(contentID: String)
        case loaded(contentID: String, name: String, avatarURL: URL?)
    }
    
    @Published private var state: PillViewState
    
    var url: URL? {
        switch state {
        case .loading:
            return nil
        case .loaded(_, _, let url):
            return url
        }
    }
    
    var name: String? {
        switch state {
        case .loading:
            return nil
        case .loaded(_, let name, _):
            return name
        }
    }
    
    var displayText: String {
        switch state {
        case .loaded(_, let name, _):
            return name
        case .loading(let contentID):
            return contentID
        }
    }
    
    var contentID: String {
        switch state {
        case .loaded(let contentID, _, _), .loading(let contentID):
            return contentID
        }
    }
    
    private var cancellable: AnyCancellable?
    
    init(roomContext: RoomScreenViewModel.Context, data: PillTextAttachmentData) {
        switch data.type {
        case let .user(id):
            if let profile = roomContext.viewState.members[id] {
                state = .loaded(contentID: id, name: profile.displayName ?? id, avatarURL: profile.avatarURL)
            } else {
                state = .loading(contentID: id)
                cancellable = roomContext.$viewState.sink { [weak self] viewState in
                    guard let self else {
                        return
                    }
                    if let profile = viewState.members[id] {
                        state = .loaded(contentID: id, name: profile.displayName ?? id, avatarURL: profile.avatarURL)
                        cancellable = nil
                    }
                }
            }
        }
    }
}

extension PillContext {
    enum MockType {
        case loadUser
        case loadedUser
    }
    
    static func mock(type: MockType) -> PillContext {
        let pillType: PillType
        switch type {
        case .loadUser:
            pillType = .user(userID: "@test:test.com")
            let viewModel = PillContext(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            Task {
                try? await Task.sleep(for: .seconds(2))
                viewModel.state = .loaded(contentID: "@test:test.com", name: "Test Longer Display Text", avatarURL: URL.documentsDirectory)
            }
            return viewModel
        case .loadedUser:
            pillType = .user(userID: "@test:test.com")
            let viewModel = PillContext(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType, font: .preferredFont(forTextStyle: .body)))
            viewModel.state = .loaded(contentID: "@test:test.com", name: "Very Very Long Test Display Text", avatarURL: URL.documentsDirectory)
            return viewModel
        }
    }
}
