//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Algorithms
import Combine
import OrderedCollections
import SwiftUI

typealias RoomPollsHistoryScreenViewModelType = StateStoreViewModel<RoomPollsHistoryScreenViewState, RoomPollsHistoryScreenViewAction>

class RoomPollsHistoryScreenViewModel: RoomPollsHistoryScreenViewModelType, RoomPollsHistoryScreenViewModelProtocol {
    private enum Constants {
        static let backPaginationEventLimit: UInt16 = 250
    }
    
    private let pollInteractionHandler: PollInteractionHandlerProtocol
    private let timelineController: TimelineControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var paginateBackwardsTask: Task<Void, Never>?
    private let isPaginatingIndicatorID = UUID().uuidString
    
    private var actionsSubject: PassthroughSubject<RoomPollsHistoryScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomPollsHistoryScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(pollInteractionHandler: PollInteractionHandlerProtocol,
         timelineController: TimelineControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.pollInteractionHandler = pollInteractionHandler
        self.timelineController = timelineController
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: RoomPollsHistoryScreenViewState(title: L10n.screenPollsHistoryTitle,
                                                                     canBackPaginate: true,
                                                                     bindings: .init(filter: .ongoing)))
        
        setupSubscriptions()
        updatePollsList(filter: state.bindings.filter)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomPollsHistoryScreenViewAction) {
        switch viewAction {
        case .edit(let pollStartID, let poll):
            actionsSubject.send(.editPoll(pollStartID: pollStartID, poll: poll))
        case .end(let pollStartID):
            endPoll(pollStartID: pollStartID)
        case .filter(let filter):
            updatePollsList(filter: filter)
        case .loadMore:
            paginateBackwards()
        case .sendPollResponse(let pollStartID, let optionID):
            sendPollResponse(pollStartID: pollStartID, optionID: optionID)
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
                    self.updatePollsList(filter: state.bindings.filter)
                case .paginationState(let paginationState):
                    let canBackPaginate = paginationState.backward != .endReached
                    if self.state.canBackPaginate != canBackPaginate {
                        self.state.canBackPaginate = canBackPaginate
                    }
                case .isLive:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.isBackPaginating)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBackPaginating in
                guard let self else { return }
                if isBackPaginating {
                    userIndicatorController.submitIndicator(.init(id: isPaginatingIndicatorID, type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false), title: L10n.commonLoading))
                } else {
                    userIndicatorController.retractIndicatorWithId(isPaginatingIndicatorID)
                }
            }
            .store(in: &cancellables)
    }
    
    private func displayError(message: String) {
        state.bindings.alertInfo = .init(id: .alert, title: message)
    }

    // MARK: - Poll Interaction Handler
    
    private func endPoll(pollStartID: String) {
        Task {
            do {
                try await pollInteractionHandler.endPoll(pollStartID: pollStartID).get()
            } catch {
                MXLog.error("Failed to end poll. \(error)")
                displayError(message: L10n.errorUnknown)
            }
        }
    }
    
    private func sendPollResponse(pollStartID: String, optionID: String) {
        Task {
            do {
                try await pollInteractionHandler.sendPollResponse(pollStartID: pollStartID, optionID: optionID).get()
            } catch {
                MXLog.error("Failed to send poll response. \(error)")
                displayError(message: L10n.errorUnknown)
            }
        }
    }
    
    // MARK: - Timeline
    
    private func updatePollsList(filter: RoomPollsHistoryFilter) {
        // Get the poll timeline items to display
        var items: [PollRoomTimelineItem] = []
        for timelineItem in timelineController.timelineItems {
            if let pollRoomTimelineItem = timelineItem as? PollRoomTimelineItem {
                // Apply the filter
                switch filter {
                case .ongoing where !pollRoomTimelineItem.poll.hasEnded:
                    items.append(pollRoomTimelineItem)
                case .past where pollRoomTimelineItem.poll.hasEnded:
                    items.append(pollRoomTimelineItem)
                default:
                    break
                }
            }
        }
        
        // Map into RoomPollsHistoryPollDetails to have both the event timestamp and the timeline item
        state.pollTimelineItems = items.map { item in
            guard let timestamp = timelineController.eventTimestamp(for: item.id) else {
                return nil
            }
            return RoomPollsHistoryPollDetails(timestamp: timestamp, item: item)
        }
        .compactMap { $0 }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    private func paginateBackwards() {
        guard paginateBackwardsTask == nil else {
            return
        }

        paginateBackwardsTask = Task { [weak self] in
            guard let self else {
                return
            }
            state.isBackPaginating = true
            switch await timelineController.paginateBackwards(requestSize: Constants.backPaginationEventLimit) {
            case .failure(let error):
                MXLog.error("failed to back paginate. \(error)")
            default:
                break
            }
            paginateBackwardsTask = nil
            state.isBackPaginating = false
        }
    }
}
