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

typealias NotificationSettingsEditScreenViewModelType = StateStoreViewModel<NotificationSettingsEditScreenViewState, NotificationSettingsEditScreenViewAction>

class NotificationSettingsEditScreenViewModel: NotificationSettingsEditScreenViewModelType, NotificationSettingsEditScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsEditScreenViewModelAction, Never> = .init()
    private let isDirect: Bool
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let userSession: UserSessionProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol?
    
    @CancellableTask private var fetchSettingsTask: Task<Void, Error>?
    @CancellableTask private var fetchRoomsTask: Task<Void, Error>?
    
    var actions: AnyPublisher<NotificationSettingsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(isDirect: Bool, userSession: UserSessionProtocol, notificationSettingsProxy: NotificationSettingsProxyProtocol) {
        let bindings = NotificationSettingsEditScreenViewStateBindings()
        self.isDirect = isDirect
        self.userSession = userSession
        self.notificationSettingsProxy = notificationSettingsProxy
        roomSummaryProvider = userSession.clientProxy.roomSummaryProvider
        
        super.init(initialViewState: NotificationSettingsEditScreenViewState(bindings: bindings,
                                                                             strings: NotificationSettingsEditScreenStrings(isDirect: isDirect),
                                                                             isDirect: isDirect),
                   imageProvider: userSession.mediaProvider)
        
        setupNotificationSettingsSubscription()
        setupRoomSummaryProviderSubscription()
    }
    
    func fetchInitialContent() {
        fetchSettings()
        updateRooms()
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
                    self.fetchSettings()
                    self.updateRooms()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchSettings() {
        fetchSettingsTask = Task {
            var mode: RoomNotificationModeProxy?
            let encrypted_mode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: isDirect)
            let unencrypted_mode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: isDirect)
            if encrypted_mode == unencrypted_mode {
                mode = encrypted_mode
            }
            guard !Task.isCancelled else { return }
            
            switch mode {
            case .allMessages:
                state.defaultMode = .allMessages
            case .mentionsAndKeywordsOnly:
                state.defaultMode = .mentionsAndKeywordsOnly
            default:
                state.defaultMode = nil
            }
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
                self?.updateRooms()
            }
            .store(in: &cancellables)
    }
    
    private func updateRooms() {
        guard let roomSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        fetchRoomsTask = Task {
            MXLog.info("Updating rooms")
            
            let roomsWithUserDefinedRules = try await notificationSettingsProxy.getRoomsWithUserDefinedRules()
            guard !Task.isCancelled else { return }
            
            let filteredRoomsSummary = roomSummaryProvider.roomListPublisher.value.filter { summary in
                roomsWithUserDefinedRules.contains(where: { summary.id == $0 })
            }
            
            var roomsWithCustomMode: [NotificationSettingsEditScreenRoom] = []
            
            for roomSummary in filteredRoomsSummary {
                switch roomSummary {
                case .empty, .invalidated:
                    break
                case .filled(let details):
                    guard let roomProxy = await userSession.clientProxy.roomForIdentifier(details.id) else { continue }
                    let isOneToOneRoom = roomProxy.activeMembersCount == 2
                    if isDirect == isOneToOneRoom {
                        await roomsWithCustomMode.append(buildRoom(with: details))
                    }
                }
            }
            
            // Sort the room list
            roomsWithCustomMode.sort(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
            
            state.roomsWithCustomSettings = roomsWithCustomMode
            
            MXLog.info("Finished updating rooms")
        }
    }
    
    private func buildRoom(with details: RoomSummaryDetails) async -> NotificationSettingsEditScreenRoom {
        let notificationMode = try? await notificationSettingsProxy.getUserDefinedRoomNotificationMode(roomId: details.id)
        return NotificationSettingsEditScreenRoom(id: details.id,
                                                  roomId: details.id,
                                                  name: details.name,
                                                  avatarURL: details.avatarURL,
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
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: isDirect, mode: roomNotificationModeProxy)
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: isDirect, mode: roomNotificationModeProxy)
            } catch {
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
