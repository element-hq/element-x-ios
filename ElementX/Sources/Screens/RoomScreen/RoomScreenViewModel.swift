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
        static let backPaginationPageSize: UInt = 30
    }

    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol

    // MARK: - Setup

    init(roomProxy: RoomProxyProtocol, timelineController: RoomTimelineControllerProtocol) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        
        super.init(initialViewState: RoomScreenViewState())
        
        state.roomTitle = roomProxy.name ?? ""
        state.timelineItems = timelineController.timelineItems
        
        timelineController.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedTimelineItems:
                self.state.timelineItems = timelineController.timelineItems
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .loadPreviousPage:
            state.isBackPaginating = true
            timelineController.paginateBackwards(Constants.backPaginationPageSize) { [weak self] _ in
                self?.state.isBackPaginating = false
            }
        case .itemAppeared:
            break
        case .itemDisappeared:
            break
        }
    }
}
