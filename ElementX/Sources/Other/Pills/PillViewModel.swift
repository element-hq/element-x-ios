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

final class PillViewModel: ObservableObject {
    enum MockType {
        case user
    }
    
    private let clientProxy: ClientProxyProtocol
    @Published private(set) var url: URL?
    @Published private(set) var name: String
    @Published private(set) var displayText: String
    let contentID: String
    
    init(clientProxy: ClientProxyProtocol, data: PillTextAttachmentData) {
        self.clientProxy = clientProxy
        switch data.type {
        case let .user(id):
            contentID = id
        }
        name = contentID
        displayText = contentID
    }
    
    static func mockViewModel(type: MockType) -> PillViewModel {
        let pillType: PillType
        switch type {
        case .user:
            pillType = .user(userId: "@test:test.com")
        }
        let viewModel = PillViewModel(clientProxy: MockClientProxy(userID: "@test:matrix.org"), data: PillTextAttachmentData(type: pillType))
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                viewModel.url = URL.documentsDirectory
                viewModel.name = "Test"
                viewModel.displayText = "Test Longer Display Text"
            }
        }
        return viewModel
    }
}
