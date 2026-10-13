//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI
import UserNotifications

/// Handles one account's notifications: its pusher, whether they're on, its unread count and its delivered notifications.
final class NotificationService: NotificationServiceProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userSettings: UserSettings
    private let notificationCenter: UserNotificationCenterProtocol
    
    /// The APNs token, unknown until the app registers for remote notifications.
    private var deviceToken: Data?
    private var cancellables = Set<AnyCancellable>()
    
    private let isEnabledSubject: CurrentValueSubject<Bool, Never>
    var isEnabledPublisher: CurrentValuePublisher<Bool, Never> {
        isEnabledSubject.asCurrentValuePublisher()
    }
    
    private let badgeCountSubject: CurrentValueSubject<Int, Never>
    var badgeCountPublisher: CurrentValuePublisher<Int, Never> {
        badgeCountSubject.asCurrentValuePublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         userSettings: UserSettings,
         notificationCenter: UserNotificationCenterProtocol) {
        self.clientProxy = clientProxy
        self.userSettings = userSettings
        self.notificationCenter = notificationCenter
        isEnabledSubject = .init(userSettings.account.enableNotifications)
        badgeCountSubject = .init(Int(clientProxy.totalUnreadNotifications))
        
        observeRoomList()
    }
    
    func register(deviceToken: Data) async {
        self.deviceToken = deviceToken
        // A failure is retried on the next launch, which registers the token again.
        _ = await updatePusher(isEnabled: isEnabledSubject.value)
    }
    
    func setEnabled(_ isEnabled: Bool) async -> Result<Void, NotificationServiceError> {
        guard await updatePusher(isEnabled: isEnabled) else {
            return .failure(.failedUpdatingPusher)
        }
        
        MXLog.info("Notifications turned \(isEnabled ? "on" : "off") for \(clientProxy.userID)")
        userSettings.account.enableNotifications = isEnabled
        isEnabledSubject.send(isEnabled)
        return .success(())
    }
    
    func removeDeliveredMessageNotifications(for roomID: String) async {
        let identifiers = await deliveredNotifications()
            .filter { $0.request.content.roomID == roomID }
            .map(\.request.identifier)
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func removeDeliveredNotificationsForFullyReadRooms(_ rooms: [RoomSummary]) async {
        let roomsToLastMessageDates = rooms
            .filter { $0.hasUnreadMessages == false }
            .reduce(into: [:]) { partialResult, roomSummary in
                partialResult[roomSummary.id] = roomSummary.lastMessageDate
            }
        
        let identifiers = await deliveredNotifications()
            .filter { notification in
                guard let roomID = notification.request.content.roomID,
                      let lastMessageDate = roomsToLastMessageDates[roomID] else {
                    return false
                }
                
                // The delivery date is later than the event's so only use it for notifications without an event date.
                let notificationDate = notification.request.content.eventDate ?? notification.date
                // Truncated to seconds to match `RoomSummary.lastMessageDate`.
                return notificationDate.timeIntervalSince1970.rounded(.down) <= lastMessageDate.timeIntervalSince1970
            }
            .map(\.request.identifier)
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func tearDown() async {
        _ = await updatePusher(isEnabled: false)
        let identifiers = await deliveredNotifications().map(\.request.identifier)
        removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // MARK: - Private
    
    private func observeRoomList() {
        let roomListPublisher = clientProxy.staticRoomSummaryProvider.roomListPublisher
        
        Task { [weak self] in
            for await roomSummaries in roomListPublisher.values {
                guard let self else { return }
                
                badgeCountSubject.send(Int(clientProxy.totalUnreadNotifications))
                await removeDeliveredNotificationsForFullyReadRooms(roomSummaries)
            }
        }
        .store(in: &cancellables)
    }
    
    /// A room can be shared with another account, so only this account's notifications are handled.
    private func deliveredNotifications() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
            // Notifications without a receiver predate multiple accounts.
            .filter { ($0.request.content.receiverID ?? clientProxy.userID) == clientProxy.userID }
    }
    
    private func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    /// Sets the pusher when enabled and deletes it otherwise. Nothing to update until the device token is known.
    private func updatePusher(isEnabled: Bool) async -> Bool {
        guard let deviceToken else { return true }
        
        let identifiers = PusherIdentifiers(pushkey: deviceToken.base64EncodedString(), appId: userSettings.app.pusherAppID)
        do {
            if isEnabled {
                try await clientProxy.setPusher(with: pusherConfiguration(identifiers: identifiers))
                MXLog.info("Set pusher succeeded")
            } else {
                try await clientProxy.deletePusher(with: identifiers)
                MXLog.info("Delete pusher succeeded")
            }
            return true
        } catch {
            MXLog.error("Updating the pusher failed: \(error)")
            return false
        }
    }
    
    private func pusherConfiguration(identifiers: PusherIdentifiers) throws -> PusherConfiguration {
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: "Notification",
                                                                      locArgs: [])),
                                         pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier)
        
        return try PusherConfiguration(identifiers: identifiers,
                                       kind: .http(data: .init(url: userSettings.app.pushGatewayNotifyEndpoint.absoluteString,
                                                               format: .eventIdOnly,
                                                               defaultPayload: defaultPayload.toJsonString())),
                                       appDisplayName: "\(InfoPlistReader.main.bundleDisplayName) (iOS)",
                                       deviceDisplayName: UIDevice.current.name,
                                       profileTag: pusherProfileTag(),
                                       lang: Bundle.app.preferredLocalizations.first ?? "en",
                                       // Otherwise accounts on the same homeserver delete each other's pusher.
                                       append: userSettings.app.multiAccountEnabled)
    }
    
    private func pusherProfileTag() -> String {
        if let currentTag = userSettings.app.pusherProfileTag {
            return currentTag
        }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let newTag = (0..<16).map { _ in
            let offset = Int.random(in: 0..<chars.count)
            return String(chars[chars.index(chars.startIndex, offsetBy: offset)])
        }.joined()
        
        userSettings.app.pusherProfileTag = newTag
        return newTag
    }
}
