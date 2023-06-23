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

    private let roomProxy: RoomProxyProtocol
    private let timelineController: RoomTimelineControllerProtocol
    private unowned let userIndicatorController: UserIndicatorControllerProtocol
    
    init(timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         roomProxy: RoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol = ServiceLocator.shared.userIndicatorController) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: RoomScreenViewState(roomId: timelineController.roomID,
                                                         roomTitle: roomProxy.roomTitle,
                                                         roomAvatarURL: roomProxy.avatarURL,
                                                         timelineStyle: ServiceLocator.shared.settings.timelineStyle,
                                                         readReceiptsEnabled: ServiceLocator.shared.settings.readReceiptsEnabled,
                                                         isEncryptedOneToOneRoom: roomProxy.isEncryptedOneToOneRoom,
                                                         bindings: .init(composerText: "", composerFocused: false)),
                   imageProvider: mediaProvider)

        setupSubscriptions()
        
        state.timelineItemMenuActionProvider = { [weak self] itemId -> TimelineItemMenuActions? in
            guard let self else {
                return nil
            }
            
            return self.timelineItemMenuActionsForItemId(itemId)
        }

        buildTimelineViews()
        
        trackComposerMode()
    }
    
    // MARK: - Public

    var callback: ((RoomScreenViewModelAction) -> Void)?
    
    // swiftlint:disable:next cyclomatic_complexity
    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .displayRoomDetails:
            callback?(.displayRoomDetails)
        case .paginateBackwards:
            Task { await paginateBackwards() }
        case .itemAppeared(let id):
            Task { await timelineController.processItemAppearance(id) }
        case .itemDisappeared(let id):
            Task { await timelineController.processItemDisappearance(id) }
        case .itemTapped(let id):
            Task { await itemTapped(with: id) }
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .sendMessage:
            Task { await sendCurrentMessage() }
        case .sendReaction(let emoji, let itemId):
            Task { await timelineController.sendReaction(emoji, to: itemId) }
        case .cancelReply:
            setComposerMode(.default)
        case .cancelEdit:
            setComposerMode(.default)
            state.bindings.composerText = ""
        case .markRoomAsRead:
            Task { await markRoomAsRead() }
        case .timelineItemMenu(let itemID):
            showTimelineItemActionMenu(for: itemID)
        case .timelineItemMenuAction(let itemID, let action):
            processTimelineItemMenuAction(action, itemID: itemID)
        case .displayCameraPicker:
            callback?(.displayCameraPicker)
        case .displayMediaPicker:
            callback?(.displayMediaPicker)
        case .displayDocumentPicker:
            callback?(.displayDocumentPicker)
        case .handlePasteOrDrop(let provider):
            handlePasteOrDrop(provider)
        case .tappedOnUser(userID: let userID):
            Task { await handleTappedUser(userID: userID) }
        case .displayEmojiPicker(let itemID):
            guard let item = state.items.first(where: { $0.id == itemID }), item.isReactable else { return }
            callback?(.displayEmojiPicker(itemID: itemID))
        case .retrySend(let transactionID):
            Task { await handleRetrySend(transactionID: transactionID) }
        case .cancelSend(let transactionID):
            Task { await handleCancelSend(transactionID: transactionID) }
        }
    }
    
    // MARK: - Private

    private func setupSubscriptions() {
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

        roomProxy
            .updatesPublisher
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state.roomTitle = roomProxy.roomTitle
                self.state.roomAvatarURL = roomProxy.avatarURL
            }
            .store(in: &cancellables)

        ServiceLocator.shared.settings.$timelineStyle
            .weakAssign(to: \.state.timelineStyle, on: self)
            .store(in: &cancellables)

        ServiceLocator.shared.settings.$readReceiptsEnabled
            .weakAssign(to: \.state.readReceiptsEnabled, on: self)
            .store(in: &cancellables)

        roomProxy.membersPublisher
            .map { members in
                members.reduce(into: [String: RoomMemberState]()) { dictionary, member in
                    dictionary[member.userID] = RoomMemberState(displayName: member.displayName, avatarURL: member.avatarURL)
                }
            }
            .weakAssign(to: \.state.members, on: self)
            .store(in: &cancellables)

        setupDirectRoomSubscriptionsIfNeeded()
    }

    private func setupDirectRoomSubscriptionsIfNeeded() {
        guard roomProxy.isDirect else {
            return
        }

        let shouldShowInviteAlert = context.$viewState
            .map(\.bindings.composerFocused)
            .removeDuplicates()
            .map { [weak self] isFocused in
                guard let self else { return false }

                return isFocused && self.roomProxy.isUserAloneInDirectRoom
            }
            // We want to show the alert just once, so we are taking the first "true" emitted
            .first { $0 }

        shouldShowInviteAlert
            .sink { [weak self] _ in
                self?.showInviteAlert()
            }
            .store(in: &cancellables)
    }

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
            callback?(.displayMediaViewer(file: file, title: title))
        case .none:
            break
        }
        state.showLoading = false
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
        return eventTimelineItem.properties.reactions.isEmpty && eventTimelineItem.sender == otherEventTimelineItem.sender
    }

    private func sendCurrentMessage() async {
        guard !state.bindings.composerText.isEmpty else {
            fatalError("This message should never be empty")
        }
        
        let currentMessage = state.bindings.composerText
        let currentComposerState = state.composerMode

        state.bindings.composerText = ""
        setComposerMode(.default)

        switch currentComposerState {
        case .reply(let itemId, _):
            await timelineController.sendMessage(currentMessage, inReplyTo: itemId)
        case .edit(let originalItemId):
            await timelineController.editMessage(currentMessage, original: originalItemId)
        default:
            await timelineController.sendMessage(currentMessage)
        }
    }
    
    private func setComposerMode(_ mode: RoomScreenComposerMode) {
        guard mode != state.composerMode else { return }
        state.composerMode = mode
        trackComposerMode()
    }
    
    private func trackComposerMode() {
        var isEdit = false
        var isReply = false
        switch state.composerMode {
        case .edit:
            isEdit = true
        case .reply:
            isReply = true
        default:
            break
        }

        ServiceLocator.shared.analytics.trackComposer(inThread: false, isEditing: isEdit, isReply: isReply, startsThread: nil)
    }
    
    private func displayError(_ type: RoomScreenErrorType) {
        switch type {
        case .alert(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: message)
        case .toast(let message):
            userIndicatorController.submitIndicator(UserIndicator(id: Constants.toastErrorID,
                                                                  type: .toast,
                                                                  title: message,
                                                                  iconName: "xmark"))
        }
    }
    
    // MARK: TimelineItemActionMenu
    
    private func showTimelineItemActionMenu(for itemID: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a menu for non-event based items.
            return
        }
        
        state.bindings.actionMenuInfo = .init(item: eventTimelineItem)
    }
    
    private func timelineItemMenuActionsForItemId(_ itemId: String) -> TimelineItemMenuActions? {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemId }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a context menu for non-event based items.
            return nil
        }
        
        if timelineItem is StateRoomTimelineItem {
            // Don't show a context menu for state events.
            return nil
        }
        
        var actions: [TimelineItemMenuAction] = [
            .reply
        ]
        
        if timelineItem is EventBasedMessageTimelineItemProtocol {
            actions.append(.forward(itemID: itemId))
        }
        
        if item.isEditable {
            actions.append(.edit)
        }
        
        if timelineItem is EventBasedMessageTimelineItemProtocol {
            actions.append(.copy)
        }
        
        actions.append(.copyPermalink)
        
        if item.isOutgoing {
            actions.append(.redact)
        } else {
            actions.append(.report)
        }
        
        var debugActions: [TimelineItemMenuAction] = ServiceLocator.shared.settings.canShowDeveloperOptions ? [.viewSource] : []
        
        if let item = timelineItem as? EncryptedRoomTimelineItem,
           case let .megolmV1AesSha2(sessionID) = item.encryptionType {
            debugActions.append(.retryDecryption(sessionID: sessionID))
        }
        
        return .init(actions: actions, debugActions: debugActions)
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func processTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        switch action {
        case .copy:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else {
                return
            }
            
            UIPasteboard.general.string = messageTimelineItem.body
        case .edit:
            guard let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol else {
                return
            }
            
            state.bindings.composerFocused = true
            state.bindings.composerText = messageTimelineItem.body
            setComposerMode(.edit(originalItemId: messageTimelineItem.id))
        case .copyPermalink:
            do {
                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventTimelineItem.id, roomIdentifier: timelineController.roomID)
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
            
            let replyDetails = TimelineItemReplyDetails.loaded(sender: eventTimelineItem.sender, contentType: buildReplyContent(for: eventTimelineItem))
            
            setComposerMode(.reply(itemID: eventTimelineItem.id, replyDetails: replyDetails))
        case .forward(let itemID):
            callback?(.displayMessageForwarding(itemID: itemID))
        case .viewSource:
            let debugInfo = timelineController.debugInfo(for: eventTimelineItem.id)
            MXLog.info(debugInfo)
            state.bindings.debugInfo = debugInfo
        case .retryDecryption(let sessionID):
            Task {
                await timelineController.retryDecryption(for: sessionID)
            }
        case .report:
            callback?(.displayReportContent(itemID: itemID, senderID: eventTimelineItem.sender.id))
        }
        
        if action.switchToDefaultComposer {
            setComposerMode(.default)
        }
    }
    
    // Pasting and dropping
    
    private func handlePasteOrDrop(_ provider: NSItemProvider) {
        guard let contentType = provider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(provider)")
            displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
            return
        }
        
        let providerSuggestedName = provider.suggestedName
        let providerDescription = provider.description
        
        _ = provider.loadDataRepresentation(for: contentType) { data, error in
            Task { @MainActor in
                let loadingIndicatorIdentifier = UUID().uuidString
                self.userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
                defer {
                    self.userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
                }

                if let error {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Failed processing NSItemProvider: \(providerDescription) with error: \(error)")
                    return
                }

                guard let data else {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Invalid NSItemProvider data: \(providerDescription)")
                    return
                }

                do {
                    let url = try await Task.detached {
                        if let filename = providerSuggestedName {
                            let hasExtension = !(filename as NSString).pathExtension.isEmpty
                            let filename = hasExtension ? filename : "\(filename).\(preferredExtension)"
                            return try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                        } else {
                            let filename = "\(UUID().uuidString).\(preferredExtension)"
                            return try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                        }
                    }.value

                    self.callback?(.displayMediaUploadPreviewScreen(url: url))
                } catch {
                    self.displayError(.toast(L10n.screenRoomErrorFailedProcessingMedia))
                    MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
                }
            }
        }
    }
    
    private func buildReplyContent(for item: EventBasedTimelineItemProtocol) -> EventBasedMessageTimelineItemContentType {
        guard let messageItem = item as? EventBasedMessageTimelineItemProtocol else {
            return .text(.init(body: item.body))
        }
        
        return messageItem.contentType
    }

    private func handleTappedUser(userID: String) async {
        // This is generally fast but it could take some time for rooms with thousands of users on first load
        // Show a loader only if it takes more than 0.1 seconds
        showLoadingIndicator(with: .milliseconds(100))
        let result = await roomProxy.getMember(userID: userID)
        hideLoadingIndicator()
        
        switch result {
        case .success(let member):
            callback?(.displayRoomMemberDetails(member: member))
        case .failure(let error):
            displayError(.alert(L10n.screenRoomErrorFailedRetrievingUserDetails))
            MXLog.error("Failed retrieving the user given the following id \(userID) with error: \(error)")
        }
    }

    private func handleRetrySend(transactionID: String?) async {
        guard let transactionID else {
            return
        }

        await roomProxy.retrySend(transactionID: transactionID)
    }

    private func handleCancelSend(transactionID: String?) async {
        guard let transactionID else {
            return
        }

        await roomProxy.cancelSend(transactionID: transactionID)
    }

    private static let loadingIndicatorIdentifier = "RoomScreenLoadingIndicator"

    private func showLoadingIndicator(with delay: Duration) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }

    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }

    // MARK: - Direct chats logics

    private func showInviteAlert() {
        userIndicatorController.alertInfo = .init(id: .init(),
                                                  title: L10n.screenRoomInviteAgainAlertTitle,
                                                  message: L10n.screenRoomInviteAgainAlertMessage,
                                                  primaryButton: .init(title: L10n.actionInvite, action: { [weak self] in self?.inviteOtherDMUserBack() }),
                                                  secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
    }

    private let inviteLoadingIndicatorID = UUID().uuidString

    private func inviteOtherDMUserBack() {
        guard roomProxy.isUserAloneInDirectRoom else {
            userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError)
            return
        }

        Task {
            userIndicatorController.submitIndicator(.init(id: inviteLoadingIndicatorID, type: .toast, title: L10n.commonLoading))
            defer {
                userIndicatorController.retractIndicatorWithId(inviteLoadingIndicatorID)
            }

            guard
                let members = await roomProxy.members(),
                members.count == 2,
                let otherPerson = members.first(where: { !$0.isAccountOwner && $0.membership == .leave })
            else {
                userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError)
                return
            }

            switch await roomProxy.invite(userID: otherPerson.userID) {
            case .success:
                break
            case .failure:
                userIndicatorController.alertInfo = .init(id: .init(),
                                                          title: L10n.commonUnableToInviteTitle,
                                                          message: L10n.commonUnableToInviteMessage)
            }
        }
    }
}

private extension RoomProxyProtocol {
    /// Checks if the other person left the room in a direct chat
    var isUserAloneInDirectRoom: Bool {
        isDirect && activeMembersCount == 1
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")))
}
