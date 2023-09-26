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

enum PillViewState {
    case loadingUser(userID: String)
    case loadedUser(userID: String, name: String, avatarURL: URL?)
}

final class PillViewModel: ObservableObject {
    enum MockType {
        case loadUser
        case loadedUser
    }
    
    @Published private var state: PillViewState
    
    var url: URL? {
        switch state {
        case .loadingUser:
            return nil
        case .loadedUser(_, _, let url):
            return url
        }
    }
    
    var name: String? {
        switch state {
        case .loadingUser:
            return nil
        case .loadedUser(_, let name, _):
            return name
        }
    }
    
    var displayText: String {
        switch state {
        case .loadedUser(_, let name, _):
            return name
        case .loadingUser(let userID):
            return userID
        }
    }
    
    var contentID: String {
        switch state {
        case .loadedUser(let userID, _, _):
            return userID
        case .loadingUser(let userID):
            return userID
        }
    }
    
    private var cancellable: AnyCancellable?
    
    @MainActor
    init(roomContext: RoomScreenViewModel.Context, data: PillTextAttachmentData) {
        switch data.type {
        case let .user(id):
            if let profile = roomContext.viewState.members[id] {
                state = .loadedUser(userID: id, name: profile.displayName ?? id, avatarURL: profile.avatarURL)
            } else {
                state = .loadingUser(userID: id)
                cancellable = roomContext.$viewState.sink { [weak self] viewState in
                    guard let self else {
                        return
                    }
                    if let profile = viewState.members[id] {
                        state = .loadedUser(userID: id, name: profile.displayName ?? id, avatarURL: profile.avatarURL)
                        cancellable = nil
                    }
                }
            }
        }
    }
    
    @MainActor
    static func mockViewModel(type: MockType) -> PillViewModel {
        let pillType: PillType
        switch type {
        case .loadUser:
            pillType = .user(userId: "@test:test.com")
            let viewModel = PillViewModel(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType))
            Task {
                try? await Task.sleep(for: .seconds(2))
                viewModel.state = .loadedUser(userID: "@test:test.com", name: "Test Longer Display Text", avatarURL: URL.documentsDirectory)
            }
            return viewModel
        case .loadedUser:
            pillType = .user(userId: "@test:test.com")
            let viewModel = PillViewModel(roomContext: RoomScreenViewModel.mock.context, data: PillTextAttachmentData(type: pillType))
            viewModel.state = .loadedUser(userID: "@test:test.com", name: "Very Very Long Test Display Text", avatarURL: URL.documentsDirectory)
            return viewModel
        }
    }
}
