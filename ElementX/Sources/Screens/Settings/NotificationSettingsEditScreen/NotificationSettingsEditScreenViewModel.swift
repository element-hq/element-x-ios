//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias NotificationSettingsEditScreenViewModelType = StateStoreViewModel<NotificationSettingsEditScreenViewState, NotificationSettingsEditScreenViewAction>

class NotificationSettingsEditScreenViewModel: NotificationSettingsEditScreenViewModelType, NotificationSettingsEditScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsEditScreenViewModelAction, Never> = .init()
    private let chatType: NotificationSettingsChatType
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let userSession: UserSessionProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    
    // periphery:ignore - cancellable tasks get cancelled when reassigned
    @CancellableTask private var fetchDefaultRoomNotificationModesTask: Task<Void, Error>?
    // periphery:ignore - cancellable tasks get cancelled when reassigned
    @CancellableTask private var updateRoomsWithUserDefinedModeTask: Task<Void, Error>?
    
    var actions: AnyPublisher<NotificationSettingsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(chatType: NotificationSettingsChatType, userSession: UserSessionProtocol, notificationSettingsProxy: NotificationSettingsProxyProtocol) {
        let bindings = NotificationSettingsEditScreenViewStateBindings()
        self.chatType = chatType
        self.userSession = userSession
        self.notificationSettingsProxy = notificationSettingsProxy
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        
        super.init(initialViewState: NotificationSettingsEditScreenViewState(bindings: bindings,
                                                                             strings: NotificationSettingsEditScreenStrings(chatType: chatType)),
                   mediaProvider: userSession.mediaProvider)
        
        setupNotificationSettingsSubscription()
        setupRoomSummaryProviderSubscription()
    }
    
    func fetchInitialContent() {
        fetchDefaultRoomNotificationModes()
        updateRoomsWithUserDefinedMode()
    }
    
    // MARK: - Public
    
    override func process(viewAction: NotificationSettingsEditScreenViewAction) {
        switch viewAction {
        case .setMode(let mode):
            setMode(mode)
        case .selectRoom(let roomIdentifier):
            actionsSubject.send(.requestRoomNotificationSettingsPresentation(roomID: roomIdentifier))
        }
    }
    
    // MARK: - Private
    
    private func setupNotificationSettingsSubscription() {
        notificationSettingsProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .settingsDidChange:
                    self.fetchDefaultRoomNotificationModes()
                    self.updateRoomsWithUserDefinedMode()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchDefaultRoomNotificationModes() {
        fetchDefaultRoomNotificationModesTask = Task {
            var mode: RoomNotificationModeProxy?
            let isOneToOne = chatType == .oneToOneChat
            let encrypted_mode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: isOneToOne)
            let unencrypted_mode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: isOneToOne)
            if encrypted_mode == unencrypted_mode {
                mode = encrypted_mode
            }
            let canPushEncryptedEvents = await notificationSettingsProxy.canPushEncryptedEventsToDevice()
            guard !Task.isCancelled else { return }
            
            switch mode {
            case .allMessages:
                state.defaultMode = .allMessages
            case .mentionsAndKeywordsOnly:
                state.defaultMode = .mentionsAndKeywordsOnly
            default:
                state.defaultMode = nil
            }
            state.canPushEncryptedEvents = canPushEncryptedEvents
        }
    }
    
    private func setupRoomSummaryProviderSubscription() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRoomsWithUserDefinedMode()
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomsWithUserDefinedMode() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        updateRoomsWithUserDefinedModeTask = Task {
            let roomsWithUserDefinedRules = try await notificationSettingsProxy.getRoomsWithUserDefinedRules()
            guard !Task.isCancelled else { return }
            
            let filteredRoomsSummary = roomSummaryProvider.roomListPublisher.value.filter { summary in
                roomsWithUserDefinedRules.contains(where: { summary.id == $0 })
            }
            
            var roomsWithUserDefinedMode: [NotificationSettingsEditScreenRoom] = []
            
            for roomSummary in filteredRoomsSummary {
                guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomSummary.id) else { continue }
                // `isOneToOneRoom` here is not the same as `isDirect` on the room. From the point of view of the push rule, a one-to-one room is a room with exactly two active members.
                let isOneToOneRoom = roomProxy.activeMembersCount == 2
                // display only the rooms we're interested in
                switch chatType {
                case .oneToOneChat where isOneToOneRoom, .groupChat where !isOneToOneRoom:
                    await roomsWithUserDefinedMode.append(buildRoom(with: roomSummary))
                default:
                    break
                }
            }
            
            // Sort the room list
            roomsWithUserDefinedMode.sort(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
            
            state.roomsWithUserDefinedMode = roomsWithUserDefinedMode
        }
    }
    
    private func buildRoom(with summary: RoomSummary) async -> NotificationSettingsEditScreenRoom {
        let notificationMode = try? await notificationSettingsProxy.getUserDefinedRoomNotificationMode(roomId: summary.id)
        return NotificationSettingsEditScreenRoom(id: summary.id,
                                                  roomId: summary.id,
                                                  name: summary.name,
                                                  avatar: summary.avatar,
                                                  notificationMode: notificationMode)
    }
    
    private func setMode(_ mode: NotificationSettingsEditScreenDefaultMode) {
        guard state.pendingMode == nil, !state.isSelected(mode: mode) else { return }
        let roomNotificationModeProxy: RoomNotificationModeProxy
        switch mode {
        case .allMessages:
            roomNotificationModeProxy = .allMessages
        case .mentionsAndKeywordsOnly:
            roomNotificationModeProxy = .mentionsAndKeywordsOnly
        }
        state.pendingMode = mode
        Task {
            do {
                // On modern clients, we don't have different settings for encrypted and non-encrypted rooms.
                let isOneToOne = chatType == .oneToOneChat
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: isOneToOne, mode: roomNotificationModeProxy)
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: isOneToOne, mode: roomNotificationModeProxy)
            } catch {
                // In case of failure, we let the user retry
                let retryAction: () -> Void = { [weak self] in
                    self?.setMode(mode)
                }
                state.bindings.alertInfo = AlertInfo(id: .setModeFailed,
                                                     title: L10n.commonError,
                                                     message: L10n.screenNotificationSettingsEditFailedUpdatingDefaultMode,
                                                     primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                                     secondaryButton: .init(title: L10n.actionRetry, action: retryAction))
            }
            state.pendingMode = nil
        }
    }
}
