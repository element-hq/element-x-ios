//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRtcKit
import SwiftUI

typealias NativeCallScreenViewModelType = StateStoreViewModelV2<NativeCallScreenViewState, NativeCallScreenViewAction>

/// Projects the app-scoped `NativeCallController` into a view state. The controller owns the call;
/// this only renders it and forwards taps.
class NativeCallScreenViewModel: NativeCallScreenViewModelType, NativeCallScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<NativeCallScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<NativeCallScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let controller: NativeCallController
    private let roomProxy: JoinedRoomProxyProtocol
    private var observationTask: Task<Void, Never>?
    private var members: [String: RoomMemberProxyProtocol] = [:]
    private var hasRequestedDismissal = false
    
    init(controller: NativeCallController, roomProxy: JoinedRoomProxyProtocol, mediaProvider: MediaProviderProtocol?) {
        self.controller = controller
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomName: roomProxy.infoPublisher.value.displayName ?? roomProxy.id),
                   mediaProvider: mediaProvider)
        
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self else { return }
                state.roomName = info.displayName ?? info.rawName ?? info.canonicalAlias ?? roomProxy.id
            }
            .store(in: &cancellables)
        
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.members = Dictionary(members.map { ($0.userID, $0) }) { first, _ in first }
                self?.refresh()
            }
            .store(in: &cancellables)
        
        observe()
    }
    
    override func process(viewAction: NativeCallScreenViewAction) {
        switch viewAction {
        case .toggleMicrophone:
            controller.setMicrophoneMuted(!(controller.call?.isMicrophoneMuted ?? false))
        case .toggleLoudspeaker:
            controller.setLoudspeaker(!controller.isLoudspeaker)
        case .minimize:
            actionsSubject.send(.minimize)
        case .hangUp:
            controller.hangUp()
        case .dismiss:
            controller.reset()
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    /// Re-reads the controller's snapshot whenever anything it (or the call) publishes changes.
    private func observe() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        self.refresh()
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    private func refresh() {
        state.connection = controller.connection
        state.connectedAt = controller.connectedAt
        state.isLoudspeaker = controller.isLoudspeaker
        state.memberCount = controller.session?.memberCount ?? 0
        
        // The call object is gone once the call ended, so this must come before the early return.
        if case .ended = controller.connection, !hasRequestedDismissal {
            hasRequestedDismissal = true
            actionsSubject.send(.dismiss)
        }
        
        guard let call = controller.call else {
            state.tiles = []
            return
        }
        state.isMicrophoneMuted = call.isMicrophoneMuted
        state.isMediaDegraded = call.isMediaDegraded
        
        state.tiles = call.participants.map { participant in
            let member = members[participant.userID]
            return NativeCallTile(memberID: participant.memberID,
                                  userID: participant.userID,
                                  displayName: participant.isLocal ? L10n.commonYou : (member?.displayName ?? participant.userID),
                                  avatarURL: member?.avatarURL,
                                  isLocal: participant.isLocal,
                                  isMicrophoneMuted: participant.isLocal ? call.isMicrophoneMuted : !participant.isPublishing(.microphone),
                                  hasMicrophone: participant.isLocal || participant.stream(.microphone) != nil,
                                  isSpeaking: call.activeSpeakerIDs.contains(participant.memberID),
                                  audioLevel: call.audioLevels[participant.memberID]?.level ?? 0)
        }
    }
}
