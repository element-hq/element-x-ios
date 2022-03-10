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
typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState,
                                                                  Never,
                                                                  RoomScreenViewAction>
@available(iOS 14, *)
class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    
    private struct Constants {
        static let backPaginationPageSize: UInt = 20
    }

    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol

    var completion: ((RoomScreenViewModelResult) -> Void)?

    // MARK: - Setup

    init(roomProxy: RoomProxyProtocol, timelineController: RoomTimelineControllerProtocol) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        
        super.init(initialViewState: RoomScreenViewState())
        
        state.messages = buildRoomScreenMessages(timelineController.timelineItems)
        
        timelineController.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedTimelineItems:
                self.state.messages = self.buildRoomScreenMessages(timelineController.timelineItems)
            }
        }.store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .loadPreviousPage:
            timelineController.paginateBackwards(Constants.backPaginationPageSize)
        }
    }
    
    // MARK: - Private
    
    private func buildRoomScreenMessages(_ timelineItems: [RoomTimelineItemProtocol]) -> [RoomScreenMessage] {
        timelineItems.map { RoomScreenMessage(id: $0.id,
                                              sender: $0.senderDisplayName,
                                              text: $0.text,
                                              originServerTs: $0.originServerTs) }
    }
}
