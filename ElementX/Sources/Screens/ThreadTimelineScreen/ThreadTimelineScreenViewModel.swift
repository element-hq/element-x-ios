//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ThreadTimelineScreenViewModelType = StateStoreViewModel<ThreadTimelineScreenViewState, ThreadTimelineScreenViewAction>

class ThreadTimelineScreenViewModel: ThreadTimelineScreenViewModelType, ThreadTimelineScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    
    private let actionsSubject: PassthroughSubject<ThreadTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ThreadTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol) {
        self.roomProxy = roomProxy
        
        super.init(initialViewState: ThreadTimelineScreenViewState())
        
        Task { [weak self] in
            for await roomInfo in roomProxy.infoPublisher.receive(on: DispatchQueue.main).values {
                guard !Task.isCancelled else {
                    return
                }
                
                await self?.handleRoomInfoUpdate(roomInfo)
            }
        }
        .store(in: &cancellables)
        
        Task {
            await handleRoomInfoUpdate(roomProxy.infoPublisher.value)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: ThreadTimelineScreenViewAction) { }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewViewModel = nil
    }
    
    func displayMediaPreview(_ mediaPreviewViewModel: TimelineMediaPreviewViewModel) {
        mediaPreviewViewModel.actions.sink { [weak self] action in
            switch action {
            case .viewInRoomTimeline:
                fatalError("viewInRoomTimeline should not be visible on a thread preview.")
            case .dismiss:
                self?.state.bindings.mediaPreviewViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        state.bindings.mediaPreviewViewModel = mediaPreviewViewModel
    }
    
    // MARK: - Private
    
    private func handleRoomInfoUpdate(_ roomInfo: RoomInfoProxy) async {
        state.canSendMessage = await (try? roomProxy.powerLevels().get().canUser(userID: roomProxy.ownUserID, sendMessage: .roomMessage).get()) == true
    }
}
