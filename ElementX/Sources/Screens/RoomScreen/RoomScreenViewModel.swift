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
import OrderedCollections
import SwiftUI

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    private enum Constants {
        static let backPaginationEventLimit: UInt = 20
        static let backPaginationPageSize: UInt = 50
        static let toastErrorID = "RoomScreenToastError"
    }

    private let timelineController: RoomTimelineControllerProtocol
    private let roomProxy: RoomProxyProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private unowned let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationCenterProtocol: NotificationCenterProtocol

    private var canCurrentUserRedact = false
    
    init(timelineController: RoomTimelineControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         roomProxy: RoomProxyProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         notificationCenterProtocol: NotificationCenterProtocol = NotificationCenter.default) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.notificationCenterProtocol = notificationCenterProtocol
        
        super.init(initialViewState: RoomScreenViewState(roomId: timelineController.roomID,
                                                         roomTitle: roomProxy.roomTitle,
                                                         roomAvatarURL: roomProxy.avatarURL,
                                                         timelineStyle: appSettings.timelineStyle,
                                                         readReceiptsEnabled: appSettings.readReceiptsEnabled,
                                                         isEncryptedOneToOneRoom: roomProxy.isEncryptedOneToOneRoom,
                                                         bindings: .init(composerText: "", composerFocused: false, reactionsCollapsed: [:])),
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
        case .toggleReaction(let emoji, let itemId):
            Task { await timelineController.toggleReaction(emoji, to: itemId) }
        case .cancelReply:
            setComposerMode(.default)
        case .cancelEdit:
            setComposerMode(.default)
            state.bindings.composerText = ""
        case .markRoomAsRead:
            Task { await markRoomAsRead() }
        case .timelineItemMenu(let itemID):
            Task {
                if case let .success(value) = await roomProxy.canUserRedact(userID: roomProxy.ownUserID) {
                    canCurrentUserRedact = value
                } else {
                    canCurrentUserRedact = false
                }
                showTimelineItemActionMenu(for: itemID)
            }
        case .timelineItemMenuAction(let itemID, let action):
            processTimelineItemMenuAction(action, itemID: itemID)
        case .displayCameraPicker:
            callback?(.displayCameraPicker)
        case .displayMediaPicker:
            callback?(.displayMediaPicker)
        case .displayDocumentPicker:
            callback?(.displayDocumentPicker)
        case .displayLocationPicker:
            callback?(.displayLocationPicker)
        case .handlePasteOrDrop(let provider):
            handlePasteOrDrop(provider)
        case .tappedOnUser(userID: let userID):
            Task { await handleTappedUser(userID: userID) }
        case .displayEmojiPicker(let itemID):
            guard let item = state.itemsDictionary[itemID.timelineID], item.isReactable else { return }
            callback?(.displayEmojiPicker(itemID: itemID))
        case .reactionSummary(let itemID, let key):
            showReactionSummary(for: itemID, selectedKey: key)
        case .retrySend(let itemID):
            Task { await handleRetrySend(itemID: itemID) }
        case .cancelSend(let itemID):
            Task { await handleCancelSend(itemID: itemID) }
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

        appSettings.$timelineStyle
            .weakAssign(to: \.state.timelineStyle, on: self)
            .store(in: &cancellables)

        appSettings.$readReceiptsEnabled
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
        notificationCenterProtocol.post(name: .roomMarkedAsRead, object: roomProxy.id)
        _ = await timelineController.markRoomAsRead()
    }

    private func itemTapped(with itemID: TimelineItemIdentifier) async {
        state.showLoading = true
        let action = await timelineController.processItemTap(itemID)

        switch action {
        case .displayMediaFile(let file, let title):
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: title)
        case .displayLocation(let body, let geoURI, let description):
            callback?(.displayLocation(body: body, geoURI: geoURI, description: description))
        case .none:
            break
        }
        state.showLoading = false
    }
        
    private func buildTimelineViews() {
        var timelineItemsDictionary = OrderedDictionary<String, RoomTimelineItemViewModel>()

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
                    timelineItemsDictionary.updateValue(updateViewModel(item: firstItem, groupStyle: .single),
                                                        forKey: firstItem.id.timelineID)
                }
            } else {
                for (index, item) in itemGroup.enumerated() {
                    if index == 0 {
                        timelineItemsDictionary.updateValue(updateViewModel(item: item, groupStyle: .first),
                                                            forKey: item.id.timelineID)
                    } else if index == itemGroup.count - 1 {
                        timelineItemsDictionary.updateValue(updateViewModel(item: item, groupStyle: .last),
                                                            forKey: item.id.timelineID)
                    } else {
                        timelineItemsDictionary.updateValue(updateViewModel(item: item, groupStyle: .middle),
                                                            forKey: item.id.timelineID)
                    }
                }
            }
        }
        
        state.itemsDictionary = timelineItemsDictionary
    }

    private func updateViewModel(item: RoomTimelineItemProtocol, groupStyle: TimelineGroupStyle) -> RoomTimelineItemViewModel {
        if let timelineItemViewModel = state.itemsDictionary[item.id.timelineID] {
            timelineItemViewModel.groupStyle = groupStyle
            timelineItemViewModel.type = .init(item: item)
            return timelineItemViewModel
        } else {
            return RoomTimelineItemViewModel(item: item, groupStyle: groupStyle)
        }
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

        analytics.trackComposer(inThread: false, isEditing: isEdit, isReply: isReply, startsThread: nil)
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
    
    private func showTimelineItemActionMenu(for itemID: TimelineItemIdentifier) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a menu for non-event based items.
            return
        }
        
        state.bindings.actionMenuInfo = .init(item: eventTimelineItem)
    }
    
    private func timelineItemMenuActionsForItemId(_ itemID: TimelineItemIdentifier) -> TimelineItemMenuActions? {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let item = timelineItem as? EventBasedTimelineItemProtocol else {
            // Don't show a context menu for non-event based items.
            return nil
        }

        if timelineItem is StateRoomTimelineItem {
            // Don't show a context menu for state events.
            return nil
        }

        var debugActions: [TimelineItemMenuAction] = appSettings.canShowDeveloperOptions ? [.viewSource] : []

        if let encryptedItem = timelineItem as? EncryptedRoomTimelineItem,
           case let .megolmV1AesSha2(sessionID) = encryptedItem.encryptionType {
            debugActions.append(.retryDecryption(sessionID: sessionID))
            return .init(actions: [], debugActions: debugActions)
        }
        
        var actions: [TimelineItemMenuAction] = [
            .reply
        ]

        if item.isMessage {
            actions.append(.forward(itemID: itemID))
        }

        if item.isEditable {
            actions.append(.edit)
        }

        if item.isMessage {
            actions.append(.copy)
        }
        
        actions.append(.copyPermalink)
        
        if canRedactItem(item) {
            actions.append(.redact)
        }

        if !item.isOutgoing {
            actions.append(.report)
        }

        if item.hasFailedToSend {
            actions = actions.filter(\.canAppearInFailedEcho)
        }

        if item.isRedacted {
            actions = actions.filter(\.canAppearInRedacted)
        }

        return .init(actions: actions, debugActions: debugActions)
    }

    private func canRedactItem(_ item: EventBasedTimelineItemProtocol) -> Bool {
        item.isOutgoing || (canCurrentUserRedact && !roomProxy.isDirect)
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func processTimelineItemMenuAction(_ action: TimelineItemMenuAction, itemID: TimelineItemIdentifier) {
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
                guard let eventID = eventTimelineItem.id.eventID else {
                    displayError(.alert(L10n.errorFailedCreatingThePermalink))
                    break
                }

                let permalink = try PermalinkBuilder.permalinkTo(eventIdentifier: eventID, roomIdentifier: timelineController.roomID,
                                                                 baseURL: appSettings.permalinkBaseURL)
                UIPasteboard.general.url = permalink
            } catch {
                displayError(.alert(L10n.errorFailedCreatingThePermalink))
            }
        case .redact:
            Task {
                if eventTimelineItem.hasFailedToSend {
                    await timelineController.cancelSend(itemID)
                } else {
                    await timelineController.redact(itemID)
                }
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

    private func handleRetrySend(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Retry Send: missing transaction ID")
            return
        }

        await roomProxy.retrySend(transactionID: transactionID)
    }

    private func handleCancelSend(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Cancel Send: missing transaction ID")
            return
        }

        await roomProxy.cancelSend(transactionID: transactionID)
    }

    private static let loadingIndicatorIdentifier = "RoomScreenLoadingIndicator"

    private func showLoadingIndicator(with delay: Duration) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
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
    
    // MARK: - Reaction summary
    
    private func showReactionSummary(for itemID: TimelineItemIdentifier, selectedKey: String) {
        guard let timelineItem = timelineController.timelineItems.first(where: { $0.id == itemID }),
              let eventTimelineItem = timelineItem as? EventBasedTimelineItemProtocol else {
            return
        }
        
        state.bindings.reactionSummaryInfo = .init(reactions: eventTimelineItem.properties.reactions, selectedKey: selectedKey)
    }
}

private extension RoomProxyProtocol {
    /// Checks if the other person left the room in a direct chat
    var isUserAloneInDirectRoom: Bool {
        isDirect && activeMembersCount == 1
    }
}

extension RoomScreenViewModel.Context {
    /// A function to make it easier to bind to reactions expand/collapsed state
    /// - Parameter itemID: The id of the timeline item the reacted to
    /// - Returns: Wether the reactions should show in the collapsed state, true by default.
    func reactionsCollapsedBinding(for itemID: TimelineItemIdentifier) -> Binding<Bool> {
        Binding(get: {
            self.reactionsCollapsed[itemID] ?? true
        }, set: {
            self.reactionsCollapsed[itemID] = $0
        })
    }
}

// MARK: - Mocks

extension RoomScreenViewModel {
    static let mock = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                          mediaProvider: MockMediaProvider(),
                                          roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                          appSettings: ServiceLocator.shared.settings,
                                          analytics: ServiceLocator.shared.analytics,
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController)
}
