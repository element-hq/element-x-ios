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
    private let roomID: String
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
        case .loadedUser(_, let name,_):
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
    
    init(clientProxy: ClientProxyProtocol, roomID: String, data: PillTextAttachmentData) {
        self.clientProxy = clientProxy
        self.roomID = roomID
        switch data.type {
        case let .user(id):
            state = .loadingUser(userID: id)
            Task {
                guard let roomProxy = await clientProxy.roomForIdentifier(roomID) else {
                    MXLog.error("Could not fetch room for mention")
                    return
                }
                
                switch await roomProxy.getMember(userID: id) {
                case .success(let profile):
                    await MainActor.run {
                        state = .loadedUser(userID: profile.userID, name: profile.displayName ?? profile.userID, avatarURL: profile.avatarURL)
                    }
                case .failure(let error):
                    MXLog.error("Could not fetch mention profile, error: \(error)")
                }
            }
        }
    }
    
    static func mockViewModel(type: MockType) -> PillViewModel {
        let pillType: PillType
        switch type {
        case .user:
            pillType = .user(userId: "@test:test.com")
        }
        let viewModel = PillViewModel(clientProxy: MockClientProxy(userID: "@test:matrix.org"), roomID: "", data: PillTextAttachmentData(type: pillType))
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                viewModel.state = .loadedUser(userID: "@test:test.com", name: "Test Longer Display Text", avatarURL: URL.documentsDirectory)
            }
        }
        return viewModel
    }
}
