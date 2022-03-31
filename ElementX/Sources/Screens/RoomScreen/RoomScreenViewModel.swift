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

    private let timelineController: RoomTimelineControllerProtocol
    private let timelineViewFactory: RoomTimelineViewFactory

    // MARK: - Setup
    
    init(timelineController: RoomTimelineControllerProtocol,
         timelineViewFactory: RoomTimelineViewFactory,
         roomName: String?) {
        self.timelineController = timelineController
        self.timelineViewFactory = timelineViewFactory
        
        super.init(initialViewState: RoomScreenViewState(roomTitle: roomName ?? "Unknown room 💥"))
        
        timelineController.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedTimelineItems:
                self.buildTimelineViews()
            case .updatedTimelineItem(let itemId):
                guard let timelineItem = self.timelineController.timelineItems.first(where: { $0.id == itemId }),
                      let viewIndex = self.state.items.firstIndex(where: { $0.id == itemId }) else {
                          return
                      }
                
                self.state.items[viewIndex] = timelineViewFactory.buildTimelineViewFor(timelineItem)
            }
        }.store(in: &cancellables)
        
        buildTimelineViews()
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .loadPreviousPage:
            state.isBackPaginating = true
            timelineController.paginateBackwards(Constants.backPaginationPageSize) { [weak self] _ in
                self?.state.isBackPaginating = false
            }
        case .itemAppeared(let id):
            timelineController.processItemAppearance(id)
        case .itemDisappeared(let id):
            timelineController.processItemDisappearance(id)
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        }
    }
    
    // MARK: - Private
    
    private func buildTimelineViews() {
        let stateItems = timelineController.timelineItems.map { item  in
            timelineViewFactory.buildTimelineViewFor(item)
        }
        
        state.items = stateItems
    }
}
