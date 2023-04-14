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

import Foundation
import UserNotifications

protocol NotificationManagerDelegate: AnyObject {
    func authorizationStatusUpdated(_ service: NotificationManagerProtocol,
                                    granted: Bool)
    func shouldDisplayInAppNotification(_ service: NotificationManagerProtocol,
                                        content: UNNotificationContent) -> Bool
    func notificationTapped(_ service: NotificationManagerProtocol,
                            content: UNNotificationContent) async
    func handleInlineReply(_ service: NotificationManagerProtocol,
                           content: UNNotificationContent,
                           replyText: String) async
}

// MARK: - NotificationManagerProtocol

// sourcery: AutoMockable
protocol NotificationManagerProtocol: AnyObject {
    var delegate: NotificationManagerDelegate? { get set }

    func start()
    func register(with deviceToken: Data) async -> Bool
    func registrationFailed(with error: Error)
    func showLocalNotification(with title: String, subtitle: String?) async
    func setClientProxy(_ clientProxy: ClientProxyProtocol?)
    func requestAuthorization()
}
