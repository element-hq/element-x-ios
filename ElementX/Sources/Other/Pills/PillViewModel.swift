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

enum PillViewState: Equatable {
    case loadingUser(userID: String)
    case loadedUser(userID: String, name: String, avatarURL: URL?)
}

final class PillViewModel: ObservableObject {
    enum MockType {
        case user
    }
    
    private let clientProxy: ClientProxyProtocol
    private let roomViewModel: RoomScreenViewModel.Context
    @Published private(set) var state: PillViewState
    
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
    init(clientProxy: ClientProxyProtocol, roomContext: RoomScreenViewModel.Context, data: PillTextAttachmentData) {
        self.clientProxy = clientProxy
        roomViewModel = roomContext
        switch data.type {
        case let .user(id):
            if let profile = roomContext.viewState.members[id] {
                state = .loadedUser(userID: id, name: profile.displayName ?? id, avatarURL: profile.avatarURL)
            } else {
                state = .loadingUser(userID: id)
                cancellable = roomContext.$viewState.sink { [weak self] viewState in
                    guard let self = self else {
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
        case .user:
            pillType = .user(userId: "@test:test.com")
        }
        let mockViewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                                mediaProvider: MockMediaProvider(),
                                                roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                                appSettings: ServiceLocator.shared.settings,
                                                analytics: ServiceLocator.shared.analytics,
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
        let viewModel = PillViewModel(clientProxy: MockClientProxy(userID: "@test:matrix.org"), roomContext: mockViewModel.context, data: PillTextAttachmentData(type: pillType))
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                viewModel.state = .loadedUser(userID: "@test:test.com", name: "Test Longer Display Text", avatarURL: URL.documentsDirectory)
            }
        }
        return viewModel
    }
}
