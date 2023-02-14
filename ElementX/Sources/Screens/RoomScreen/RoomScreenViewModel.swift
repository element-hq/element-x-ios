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

import Combine
import SwiftUI

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    private enum Constants {
        static let backPaginationEventLimit: UInt = 20
        static let backPaginationPageSize: UInt = 50
        static let toastErrorID = "RoomScreenToastError"
    }

    private let timelineController: RoomTimelineControllerProtocol
    private let timelineViewFactory: RoomTimelineViewFactoryProtocol
    
    init(timelineController: RoomTimelineControllerProtocol,
         timelineViewFactory: RoomTimelineViewFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         roomName: String?,
         roomAvatarUrl: URL? = nil) {
        self.timelineController = timelineController
        self.timelineViewFactory = timelineViewFactory
        
        super.init(initialViewState: RoomScreenViewState(roomId: timelineController.roomID,
                                                         roomTitle: roomName ?? "Unknown room 💥",
                                                         roomAvatarURL: roomAvatarUrl,
                                                         timelineStyle: ServiceLocator.shared.settings.timelineStyle,
                                                         bindings: .init(composerText: "", composerFocused: false)),
                   imageProvider: mediaProvider)
        
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
                case .canBackPaginate(let canBackPaginate):
                    if self.state.canBackPaginate != canBackPaginate {
                        self.state.canBackPaginate = canBackPaginate
                    }
                case .isBackPaginating(let isBackPaginating):
                    if self.state.isBackPaginating != isBackPaginating {
                        self.state.isBackPaginating = isBackPaginating
                    }
                }
            }
            .store(in: &cancellables)
        
        state.contextMenuActionProvider = { [weak self] itemId -> TimelineItemContextMenuActions? in
            guard let self else {
                return nil
            }
            
            return self.contextMenuActionsForItemId(itemId)
        }
        
        ServiceLocator.shared.settings.$timelineStyle
            .weakAssign(to: \.state.timelineStyle, on: self)
            .store(in: &cancellables)
        
        buildTimelineViews()
    }
    
    // MARK: - Public

    var callback: ((RoomScreenViewModelAction) -> Void)?
    
    // swiftlint:disable:next cyclomatic_complexity
    override func process(viewAction: RoomScreenViewAction) async {
        switch viewAction {
        case .displayRoomDetails:
            callback?(.displayRoomDetails)
        case .paginateBackwards:
            await paginateBackwards()
        case .itemAppeared(let id):
            await timelineController.processItemAppearance(id)
        case .itemDisappeared(let id):
            await timelineController.processItemDisappearance(id)
        case .itemTapped(let id):
            await itemTapped(with: id)
        case .itemDoubleTapped(let id):
            itemDoubleTapped(with: id)
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .sendMessage:
            await sendCurrentMessage()
        case .sendReaction(let emoji, let itemId):
            await timelineController.sendReaction(emoji, to: itemId)
        case .cancelReply:
            state.composerMode = .default
        case .cancelEdit:
            state.composerMode = .default
            state.bindings.composerText = ""
        case .markRoomAsRead:
            await markRoomAsRead()
        case .contextMenuAction(let itemID, let action):
            processContentMenuAction(action, itemID: itemID)
        }
    }
    
    // MARK: - Private
    
    private func paginateBackwards() async {
        switch await timelineController.paginateBackwards(requestSize: Constants.backPaginationEventLimit, untilNumberOfItems: Constants.backPaginationPageSize) {
        case .failure:
            displayError(.toast(ElementL10n.roomTimelineBackpaginationFailure))
        default:
            break
        }
    }
    
    private func markRoomAsRead() async {
        _ = await timelineController.markRoomAsRead()
    }

    private func itemTapped(with itemId: String) async {
        state.showLoading = true
        let action = await timelineController.processItemTap(itemId)

        switch action {
        case .displayVideo(let videoURL, let title):
            callback?(.displayVideo(videoURL: videoURL, title: title))
        case .displayFile(let fileURL, let title):
            callback?(.displayFile(fileURL: fileURL, title: title))
        case .none:
            break
        }
        state.showLoading = false
    }
    
    private func itemDoubleTapped(with itemId: String) {
        guard let item = state.items.first(where: { $0.id == itemId }), item.isReactable else { return }
        callback?(.displayEmojiPicker(itemId: itemId))
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
            await timelineController.sendMessage(currentMessage, inReplyTo: itemId)
        case .edit(let originalItemId):
            await timelineController.editMessage(currentMessage, original: originalItemId)
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
        case .toast(let message):
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Constants.toastErrorID,
                                                                                        type: .toast,
                                                                                        title: message,
                                                                                        iconName: "xmark"))
        }
    }
    
    // MARK: ContextMenus
    
    private func contextMenuActionsForItemId(_ itemId: String) -> TimelineItemContextMenuActions? {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a context menu for non-event based items.
            return nil
        }
        
        if timelineItem is StateRoomTimelineItem {
            // Don't show a context menu for state events.
            return nil
        }
        
        var actions: [TimelineItemContextMenuAction] = [
            .react, .copy, .reply
            // Disabled for FOSDEM
            // .quote, .copyPermalink
        ]

        if item.isEditable {
            actions.append(.edit)
        }
        
        if item.isOutgoing {
            actions.append(.redact)
        }
        
        var debugActions: [TimelineItemContextMenuAction] = [.viewSource]
        
        if let item = timelineItem as? EncryptedRoomTimelineItem,
           case let .megolmV1AesSha2(sessionID) = item.encryptionType {
            debugActions.append(.retryDecryption(sessionID: sessionID))
        }
        
        return .init(actions: actions, debugActions: debugActions)
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func processContentMenuAction(_ action: TimelineItemContextMenuAction, itemID: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .react:
            callback?(.displayEmojiPicker(itemId: item.id))
        case .copy:
            UIPasteboard.general.string = item.body
        case .edit:
            state.bindings.composerFocused = true
            state.bindings.composerText = item.body
            state.composerMode = .edit(originalItemId: item.id)
        case .quote:
            state.bindings.composerFocused = true
            state.bindings.composerText = "> \(item.body)"
        case .copyPermalink:
            do {
                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: item.id, roomIdentifier: timelineController.roomID)
                UIPasteboard.general.url = permalink
            } catch {
                displayError(.alert(ElementL10n.roomTimelinePermalinkCreationFailure))
            }
        case .redact:
            Task {
                await timelineController.redact(itemID)
            }
        case .reply:
            state.bindings.composerFocused = true
            state.composerMode = .reply(id: item.id, displayName: item.sender.displayName ?? item.sender.id)
        case .viewSource:
            let debugDescription = timelineController.debugDescription(for: item.id)
            MXLog.info(debugDescription)
            state.bindings.debugInfo = .init(title: "Timeline item", content: debugDescription)
        case .retryDecryption(let sessionID):
            Task {
                await timelineController.retryDecryption(for: sessionID)
            }
        }
        
        if action.switchToDefaultComposer {
            state.composerMode = .default
        }
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                          timelineViewFactory: RoomTimelineViewFactory(),
                                          mediaProvider: MockMediaProvider(),
                                          roomName: "Preview room")
}
