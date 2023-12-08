//
// Copyright 2023 New Vector Ltd
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
import Foundation
import UIKit

@MainActor
protocol RoomPollsHistoryTimelineControllerProtocol {
    var firstTimelineEventDate: Date? { get }
    
    var timelineItems: [RoomTimelineItemProtocol] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
        
    func paginateBackwards(requestSize: UInt) async -> Result<Void, RoomTimelineControllerError>
    
    func timestamp(for itemID: TimelineItemIdentifier) -> Date?
}

class RoomPollsHistoryTimelineController: RoomPollsHistoryTimelineControllerProtocol {
    private let roomProxy: RoomProxyProtocol
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let appSettings: AppSettings
    private let secureBackupController: SecureBackupControllerProtocol
    
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    private var timelineItemsUpdateTask: Task<Void, Never>? {
        willSet {
            timelineItemsUpdateTask?.cancel()
        }
    }
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems: [RoomTimelineItemProtocol] = []
    private(set) var timelineItemsTimestamp: [TimelineItemIdentifier: Date] = [:]
    private(set) var firstTimelineEventDate: Date?
    
    init(roomProxy: RoomProxyProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         appSettings: AppSettings,
         secureBackupController: SecureBackupControllerProtocol) {
        self.roomProxy = roomProxy
        timelineProvider = roomProxy.pollHistoryTimeline.timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.appSettings = appSettings
        self.secureBackupController = secureBackupController
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roompollshistorytimelineprovider", qos: .utility)
        
        timelineProvider
            .updatePublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.updateTimelineItems()
            }
            .store(in: &cancellables)
        
        serialDispatchQueue.async {
            self.updateTimelineItems()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(requestSize: UInt) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started back pagination request")
        switch await roomProxy.pollHistoryTimeline.paginateBackwards(requestSize: requestSize) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func timestamp(for itemID: TimelineItemIdentifier) -> Date? {
        timelineItemsTimestamp[itemID]
    }
    
    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        var newTimelineItemsTimestamp = [TimelineItemIdentifier: Date]()
        var canBackPaginate = true
        var isBackPaginating = false

        let firstTimelineEvent = timelineProvider.itemProxies.first(where: {
            switch $0 {
            case .event:
                true
            default:
                false
            }
        })

        if case .event(let firstEvent) = firstTimelineEvent {
            firstTimelineEventDate = firstEvent.timestamp
            
            let age = Date.now.timeIntervalSince(firstEvent.timestamp)
            let dateComponents = Calendar.current.dateComponents([.day], from: firstEvent.timestamp, to: .now)
            let days = (dateComponents.day ?? 0) + 1
            MXLog.info("first timeline item age: \(age) [\(days) days]")
        }

        for item in timelineProvider.itemProxies {
            if let timelineItem = buildTimelineItem(for: item) {
                if timelineItem.roomTimelineItem is EncryptedHistoryRoomTimelineItem {
                    canBackPaginate = false
                    continue
                }
            
                newTimelineItems.append(timelineItem.roomTimelineItem)
                newTimelineItemsTimestamp[timelineItem.roomTimelineItem.id] = timelineItem.timestamp
            }
        }
        
        switch timelineProvider.backPaginationState {
        case .timelineStartReached:
            canBackPaginate = false
        case .paginating:
            isBackPaginating = true
        case .idle:
            break
        }
        
        timelineItems = newTimelineItems
        timelineItemsTimestamp = newTimelineItemsTimestamp
        
        callbacks.send(.canBackPaginate(canBackPaginate))
        callbacks.send(.isBackPaginating(isBackPaginating))
        callbacks.send(.updatedTimelineItems)
    }
    
    private func buildTimelineItem(for itemProxy: TimelineItemProxy) -> (roomTimelineItem: RoomTimelineItemProtocol, timestamp: Date)? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            guard let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem) else {
                return nil
            }
            
            if timelineItem is EncryptedRoomTimelineItem, isItemInEncryptionHistory(eventTimelineItem) {
                return (roomTimelineItem: EncryptedHistoryRoomTimelineItem(id: eventTimelineItem.id,
                                                                           isSessionVerified: secureBackupController.keyBackupState.value != .unknown),
                        timestamp: eventTimelineItem.timestamp)
            }
            
            // We only returns PollRoomTimelineItem
            return (roomTimelineItem: timelineItem, timestamp: eventTimelineItem.timestamp)
        case .virtual:
            return nil
        case .unknown:
            return nil
        }
    }
    
    /// Whether or not a specific item is part of the room's history that can't be decrypted due
    /// to the lack of key-backup. This is handled differently so we only show a single item.
    private func isItemInEncryptionHistory(_ itemProxy: EventTimelineItemProxy) -> Bool {
        guard roomProxy.isEncrypted, let lastLoginDate = appSettings.lastLoginDate else { return false }
        return itemProxy.timestamp < lastLoginDate
    }
    
    private func fetchEventDetails(for timelineItem: EventBasedMessageTimelineItemProtocol, refetchOnError: Bool) {
        guard let eventID = timelineItem.id.eventID else {
            return
        }

        switch timelineItem.replyDetails {
        case .notLoaded:
            roomProxy.pollHistoryTimeline.fetchDetails(for: eventID)
        case .error:
            if refetchOnError {
                roomProxy.pollHistoryTimeline.fetchDetails(for: eventID)
            }
        default:
            break
        }
    }
}
