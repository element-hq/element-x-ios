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

import Algorithms
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
    
    init(timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         roomName: String?,
         roomAvatarUrl: URL? = nil) {
        self.timelineController = timelineController
        
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
            displayError(.toast(L10n.errorFailedLoadingMessages))
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
        case .displayMediaFile(let file, let title):
            callback?(.displayMediaFile(file: file, title: title))
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
        var timelineViews = [RoomTimelineViewProvider]()
        
        let itemsGroupedByTimelineDisplayStyle = timelineController.timelineItems.chunked { current, next in
            canGroupItem(timelineItem: current, with: next)
        }
        
        for itemGroup in itemsGroupedByTimelineDisplayStyle {
            guard !itemGroup.isEmpty else {
                MXLog.error("Found empty item group")
                continue
            }
            
            if itemGroup.count == 1 {
                if let firstItem = itemGroup.first {
                    timelineViews.append(RoomTimelineViewProvider(timelineItem: firstItem, groupStyle: .single))
                }
            } else {
                for (index, item) in itemGroup.enumerated() {
                    if index == 0 {
                        timelineViews.append(RoomTimelineViewProvider(timelineItem: item, groupStyle: .first))
                    } else if index == itemGroup.count - 1 {
                        timelineViews.append(RoomTimelineViewProvider(timelineItem: item, groupStyle: .last))
                    } else {
                        timelineViews.append(RoomTimelineViewProvider(timelineItem: item, groupStyle: .middle))
                    }
                }
            }
        }
        
        state.items = timelineViews
    }
        
    private func canGroupItem(timelineItem: RoomTimelineItemProtocol, with otherTimelineItem: RoomTimelineItemProtocol) -> Bool {
        if timelineItem is CollapsibleTimelineItem || otherTimelineItem is CollapsibleTimelineItem {
            return false
        }
        
        guard let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol,
              let otherEventTimelineItem = otherTimelineItem as? EventBasedTimelineItemProtocol else {
            return false
        }
        
        // State events aren't rendered as messages so shouldn't be grouped.
        if eventTimelineItem is StateRoomTimelineItem || otherEventTimelineItem is StateRoomTimelineItem {
            return false
        }
        
        //  can be improved by adding a date threshold
        return otherEventTimelineItem.properties.reactions.isEmpty && eventTimelineItem.sender == otherEventTimelineItem.sender
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
                                                 title: L10n.commonError,
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
        } else {
            actions.append(.report)
        }
        
        var debugActions: [TimelineItemContextMenuAction] = ServiceLocator.shared.settings.canShowDeveloperOptions ? [.viewSource] : []
        
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
                displayError(.alert(L10n.errorFailedCreatingThePermalink))
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
        case .report:
            callback?(.displayReportContent(itemId: itemID))
        }
        
        if action.switchToDefaultComposer {
            state.composerMode = .default
        }
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          roomName: "Preview room")
}
