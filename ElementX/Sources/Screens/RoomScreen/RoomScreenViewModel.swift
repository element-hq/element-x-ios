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
        static let backPaginationPageSize: UInt = 50
    }

    private let timelineController: RoomTimelineControllerProtocol
    private let timelineViewFactory: RoomTimelineViewFactoryProtocol
    private let mediaProvider: MediaProviderProtocol

    // MARK: - Setup
    
    init(timelineController: RoomTimelineControllerProtocol,
         timelineViewFactory: RoomTimelineViewFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         roomName: String?,
         roomAvatarUrl: String? = nil) {
        self.timelineController = timelineController
        self.timelineViewFactory = timelineViewFactory
        self.mediaProvider = mediaProvider
        
        super.init(initialViewState: RoomScreenViewState(roomId: timelineController.roomId,
                                                         roomTitle: roomName ?? "Unknown room 💥",
                                                         roomAvatar: nil,
                                                         bindings: .init(composerText: "", composerFocused: false)))
        
        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .updatedTimelineItems:
                    self.buildTimelineViews()
                case .updatedTimelineItem(let itemId):
                    guard let timelineItem = self.timelineController.timelineItems.first(where: { $0.id == itemId }),
                          let viewIndex = self.state.items.firstIndex(where: { $0.id == itemId }) else {
                        return
                    }
                    
                    self.state.items[viewIndex] = timelineViewFactory.buildTimelineViewFor(timelineItem: timelineItem)
                case .startedBackPaginating:
                    self.state.isBackPaginating = true
                case .finishedBackPaginating:
                    self.state.isBackPaginating = false
                }
            }
            .store(in: &cancellables)
        
        state.contextMenuBuilder = buildContexMenuForItemId(_:)
        
        buildTimelineViews()

        if let roomAvatarUrl {
            Task {
                if case let .success(avatar) = await mediaProvider.loadImageFromURLString(roomAvatarUrl,
                                                                                          avatarSize: .room(on: .timeline)) {
                    state.roomAvatar = avatar
                }
            }
        }
    }
    
    // MARK: - Public

    var callback: ((RoomScreenViewModelAction) -> Void)?
    
    override func process(viewAction: RoomScreenViewAction) async {
        switch viewAction {
        case .loadPreviousPage:
            switch await timelineController.paginateBackwards(Constants.backPaginationPageSize) {
            default:
                #warning("Treat errors")
            }
        case .itemAppeared(let id):
            await timelineController.processItemAppearance(id)
        case .itemDisappeared(let id):
            await timelineController.processItemDisappearance(id)
        case .itemTapped(let id):
            await itemTapped(with: id)
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .sendMessage:
            await sendCurrentMessage()
        case .sendReaction(let key, _):
            #warning("Reaction implementation awaiting SDK support.")
            MXLog.warning("React with \(key) failed. Not implemented.")
        case .cancelReply:
            state.composerMode = .default
        case .cancelEdit:
            state.composerMode = .default
        }
    }

    func stop() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        state.contextMenuBuilder = nil
    }
    
    // MARK: - Private

    private func itemTapped(with itemId: String) async {
        let action = await timelineController.processItemTap(itemId)

        switch action {
        case .displayMedia(let mediaURL):
            callback?(.displayMedia(mediaURL: mediaURL))
        case .none:
            break
        }
    }
    
    private func buildTimelineViews() {
        let stateItems = timelineController.timelineItems.map { item in
            timelineViewFactory.buildTimelineViewFor(timelineItem: item)
        }
        
        state.items = stateItems
    }
    
    private func sendCurrentMessage() async {
        guard !state.bindings.composerText.isEmpty else {
            fatalError("This message should never be empty")
        }
        
        let currentMessage = state.bindings.composerText
        let currentComposerState = state.composerMode

        state.bindings.composerText = ""
        state.composerMode = .default

        switch currentComposerState {
        case .reply(let itemId, _):
            await timelineController.sendReply(currentMessage, to: itemId)
        case .edit(let originalItemId):
            await timelineController.editMessage(currentMessage, of: originalItemId)
        default:
            await timelineController.sendMessage(currentMessage)
        }
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
    
    private func contextMenuActionsForItemId(_ itemId: String) -> TimelineItemContextMenuActions {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            return .init(actions: [])
        }
        
        var actions: [TimelineItemContextMenuAction] = [
            .copy, .quote, .copyPermalink, .reply
        ]

        if item.isEditable {
            actions.append(.edit)
        }
        
        if item.isOutgoing {
            actions.append(.redact)
        }
        
        return .init(actions: actions)
    }
    
    private func processContentMenuAction(_ action: TimelineItemContextMenuAction, itemId: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            UIPasteboard.general.string = item.text
        case .edit:
            state.bindings.composerFocused = true
            state.bindings.composerText = item.text
            state.composerMode = .edit(originalItemId: item.id)
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
            state.composerMode = .reply(id: item.id, displayName: item.senderDisplayName ?? item.senderId)
        case .viewSource:
            let debugDescription = timelineController.debugDescriptionFor(item.id)
            MXLog.info(debugDescription)
            state.bindings.debugInfo = .init(title: "Timeline item", content: debugDescription)
        }
        
        if action.switchToDefaultComposer {
            state.composerMode = .default
        }
    }
    
    private func redact(_ eventID: String) {
        Task {
            await timelineController.redact(eventID)
        }
    }
}
