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

typealias RoomPollsHistoryScreenViewModelType = StateStoreViewModel<RoomPollsHistoryScreenViewState, RoomPollsHistoryScreenViewAction>

class RoomPollsHistoryScreenViewModel: RoomPollsHistoryScreenViewModelType, RoomPollsHistoryScreenViewModelProtocol {
    private enum Constants {
        static let backPaginationEventLimit: UInt = 200
        static let toastErrorID = "RoomPollsHistoryScreenToastError"
    }
    
    private let pollInteractionHandler: PollInteractionHandlerProtocol
    private let roomPollsHistoryTimelineController: RoomPollsHistoryTimelineControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appSettings: AppSettings
    
    private var paginateBackwardsTask: Task<Void, Never>?
    private let isPaginatingIndicatorID = UUID().uuidString
    
    private var actionsSubject: PassthroughSubject<RoomPollsHistoryScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomPollsHistoryScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(pollInteractionHandler: PollInteractionHandlerProtocol,
         roomPollsHistoryTimelineController: RoomPollsHistoryTimelineControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings) {
        self.pollInteractionHandler = pollInteractionHandler
        self.roomPollsHistoryTimelineController = roomPollsHistoryTimelineController
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        
        super.init(initialViewState: RoomPollsHistoryScreenViewState(title: UntranslatedL10n.screenPollsHistoryTitle,
                                                                     canBackPaginate: false,
                                                                     isInitializing: true,
                                                                     bindings: .init(filter: .ongoing)))
        
        setupSubscriptions()
        
        paginateBackwards()
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
        roomPollsHistoryTimelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .updatedTimelineItems:
                    self.updatePollsList(filter: state.bindings.filter)
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
    
    // MARK: - Timeline Item Building
    
    private func updatePollsList(filter: RoomPollsHistoryFilter) {
        // Get the poll timeline items to display
        var items: [PollRoomTimelineItem] = []
        for timelineItem in roomPollsHistoryTimelineController.timelineItems {
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
            guard let timestamp = roomPollsHistoryTimelineController.timestamp(for: item.id) else {
                return nil
            }
            return RoomPollsHistoryPollDetails(timestamp: timestamp, item: item)
        }
        .compactMap { $0 }
        .sorted { $0.timestamp > $1.timestamp }

        // Update the number of loaded days
        if let firstItemDate = roomPollsHistoryTimelineController.firstTimelineEventDate {
            let dateComponents = Calendar.current.dateComponents([.day], from: firstItemDate, to: .now)
            state.loadedDays = (dateComponents.day ?? 0) + 1
        }
    }
    
    private func paginateBackwards() {
        guard paginateBackwardsTask == nil else {
            return
        }

        userIndicatorController.submitIndicator(.init(id: isPaginatingIndicatorID, type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false), title: L10n.commonLoading))
        paginateBackwardsTask = Task { [weak self] in
            defer {
                self?.state.isInitializing = false
                userIndicatorController.retractIndicatorWithId(isPaginatingIndicatorID)
            }
            guard let self else {
                return
            }

            state.isBackPaginating = true
            switch await roomPollsHistoryTimelineController.paginateBackwards(requestSize: Constants.backPaginationEventLimit) {
            case .failure(let error):
                MXLog.error("failed to back paginate. \(error)")
                state.isBackPaginating = false
            default:
                break
            }
            paginateBackwardsTask = nil
        }
    }
}

// MARK: - Mocks

extension RoomPollsHistoryScreenViewModel {
    static let mock = RoomPollsHistoryScreenViewModel(pollInteractionHandler: PollInteractionHandlerMock(),
                                                      roomPollsHistoryTimelineController: MockRoomPollsHistoryTimelineController(),
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      appSettings: ServiceLocator.shared.settings)
}
