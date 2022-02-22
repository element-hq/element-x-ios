//
// Copyright 2021 New Vector Ltd
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

import SwiftUI

@available(iOS 14, *)
typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState,
                                                        Never,
                                                        HomeScreenViewAction>
@available(iOS 14, *)
class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var roomList: [RoomModelProtocol]?

    // MARK: Public

    var completion: ((HomeScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userDisplayName: String) {
        super.init(initialViewState: HomeScreenViewState(userDisplayName: userDisplayName))
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .logout:
            self.completion?(.logout)
        case .loadRoomAvatar(let roomId):
            guard let room = roomList?.filter({ $0.identifier == roomId }).first else {
                break
            }
            
            room.getAvatar { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let image):
                    guard let index = self.state.rooms.firstIndex(where: { $0.id == roomId }) else {
                        return
                    }
                    
                    self.state.rooms[index].avatar = image
                default:
                    break
                }
            }
        case .loadUserAvatar:
            self.completion?(.loadUserAvatar)
        }
    }
    
    func updateWithRoomList(_ roomList: [RoomModelProtocol]) {
        self.roomList = roomList
        state.rooms = roomList.map { roomModel in
            HomeScreenRoom(id: roomModel.identifier,
                           displayName: roomModel.displayName,
                           topic: roomModel.topic,
                           lastMessage: roomModel.lastMessage,
                           isDirect: roomModel.isDirect,
                           isEncrypted: roomModel.isEncrypted)
        }
    }
    
    func updateWithUserAvatar(_ avatar: UIImage?) {
        self.state.userAvatar = avatar
    }
}
