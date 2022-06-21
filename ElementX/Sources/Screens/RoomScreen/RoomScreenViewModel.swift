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

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    
    private struct Constants {
        static let backPaginationPageSize: UInt = 30
    }

    private let timelineController: RoomTimelineControllerProtocol
    private let timelineViewFactory: RoomTimelineViewFactoryProtocol

    // MARK: - Setup
    
    init(timelineController: RoomTimelineControllerProtocol,
         timelineViewFactory: RoomTimelineViewFactoryProtocol,
         roomName: String?,
         roomAvatar: UIImage? = nil,
         roomEncryptionBadge: UIImage? = nil) {
        self.timelineController = timelineController
        self.timelineViewFactory = timelineViewFactory
        
        super.init(initialViewState: RoomScreenViewState(roomTitle: roomName ?? "Unknown room 💥",
                                                         roomAvatar: roomAvatar,
                                                         roomEncryptionBadge: roomEncryptionBadge,
                                                         bindings: .init(composerText: "")))
        
        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self = self else { return }
                
                switch callback {
                case .updatedTimelineItems:
                    self.buildTimelineViews()
                case .updatedTimelineItem(let itemId):
                    guard let timelineItem = self.timelineController.timelineItems.first(where: { $0.id == itemId }),
                          let viewIndex = self.state.items.firstIndex(where: { $0.id == itemId }) else {
                        return
                    }
                    
                    self.state.items[viewIndex] = timelineViewFactory.buildTimelineViewFor(timelineItem: timelineItem)
                }
            }.store(in: &cancellables)
        
        state.contextMenuBuilder = buildContexMenuForItemId(_:)
        
        buildTimelineViews()
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomScreenViewAction) async {
        switch viewAction {
        case .loadPreviousPage:
            state.isBackPaginating = true
            
            switch await timelineController.paginateBackwards(Constants.backPaginationPageSize) {
            default:
                state.isBackPaginating = false
            }
            
        case .itemAppeared(let id):
            await timelineController.processItemAppearance(id)
        case .itemDisappeared(let id):
            await timelineController.processItemDisappearance(id)
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .sendMessage:
            guard state.bindings.composerText.count > 0 else {
                return
            }
            
            await timelineController.sendMessage(state.bindings.composerText)
            state.bindings.composerText = ""
        }
    }
    
    // MARK: - Private
    
    private func buildTimelineViews() {
        let stateItems = timelineController.timelineItems.map { item  in
            timelineViewFactory.buildTimelineViewFor(timelineItem: item)
        }
        
        state.items = stateItems
    }
    
    // MARK: ContextMenus
    
    private func buildContexMenuForItemId(_ itemId: String) -> TimelineItemContextMenu {
        TimelineItemContextMenu(contextMenuActions: self.contextMenuActionsForItemId(itemId)) { [weak self] action in
            self?.processContentMenuAction(action, itemId: itemId)
        }
    }
    
    private func contextMenuActionsForItemId(_ itemId: String) -> [TimelineItemContextMenuAction] {
        guard let timelineItem = self.timelineController.timelineItems.first(where: { $0.id == itemId }),
              timelineItem is EventBasedTimelineItemProtocol else {
            return []
        }
        
        return [.copy, .quote]
    }
    
    private func processContentMenuAction(_ action: TimelineItemContextMenuAction, itemId: String) {
        guard let timelineItem = self.timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            UIPasteboard.general.string = item.text
        case .quote:
            state.bindings.composerText = "> \(item.text)"
        }
    }
}
