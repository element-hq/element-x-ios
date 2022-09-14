//
// Copyright 2022 New Vector Ltd
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
    private enum Constants {
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
                                                         bindings: .init(composerText: "", composerFocused: false)))
        
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
            await sendCurrentMessage()
        case .sendReaction(let key, _):
            #warning("Reaction implementation awaiting SDK support.")
            MXLog.warning("React with \(key) failed. Not implemented.")
        case .cancelReply:
            state.composerType = .default
        }
    }
    
    // MARK: - Private
    
    private func buildTimelineViews() {
        let stateItems = timelineController.timelineItems.map { item in
            timelineViewFactory.buildTimelineViewFor(timelineItem: item)
        }
        
        state.items = stateItems
    }
    
    private func sendCurrentMessage() async {
        guard state.bindings.composerText.count > 0 else {
            fatalError("This message should never be empty")
        }
        
        state.messageComposerDisabled = true
        
        switch state.composerType {
        case .reply(let id, _):
            await timelineController.sendReplyTo(id, state.bindings.composerText)
        default:
            await timelineController.sendMessage(state.bindings.composerText)
        }
        
        state.bindings.composerText = ""
        state.composerType = .default
        
        state.messageComposerDisabled = false
    }
    
    private func displayError(_ type: RoomScreenErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: ElementL10n.dialogTitleError,
                                                 message: message)
        }
    }
    
    // MARK: ContextMenus
    
    private func buildContexMenuForItemId(_ itemId: String) -> TimelineItemContextMenu {
        TimelineItemContextMenu(contextMenuActions: contextMenuActionsForItemId(itemId)) { [weak self] action in
            self?.processContentMenuAction(action, itemId: itemId)
        }
    }
    
    private func contextMenuActionsForItemId(_ itemId: String) -> [TimelineItemContextMenuAction] {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              timelineItem is EventBasedTimelineItemProtocol else {
            return []
        }
        
        let actions: [TimelineItemContextMenuAction] = [
            .copy, .quote, .copyPermalink, .reply
        ]
        
        #warning("Outgoing actions to be handled with the new Timeline API.")
//        if timelineItem.isOutgoing {
//            actions.append(.redact)
//        }
        
        return actions
    }
    
    private func processContentMenuAction(_ action: TimelineItemContextMenuAction, itemId: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            UIPasteboard.general.string = item.text
        case .quote:
            state.bindings.composerFocused = true
            state.bindings.composerText = "> \(item.text)"
        case .copyPermalink:
            do {
                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: item.id, roomIdentifier: timelineController.roomId)
                UIPasteboard.general.url = permalink
            } catch {
                displayError(.alert(ElementL10n.roomTimelinePermalinkCreationFailure))
            }
        case .redact:
            redact(itemId)
        case .reply:
            state.bindings.composerFocused = true
        }
        
        switch action {
        case .reply:
            state.composerType = .reply(id: item.id, displayName: item.senderDisplayName ?? item.senderId)
        default:
            state.composerType = .default
        }
    }
    
    private func redact(_ eventID: String) {
        Task {
            await timelineController.redact(eventID)
        }
    }
}
