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

import SwiftUI

class UserNotificationController: ObservableObject, UserNotificationControllerProtocol {
    private let rootCoordinator: CoordinatorProtocol
    
    private var dismisalTimer: Timer?
    private var displayTimes = [String: Date]()
    
    var nonPersistentDisplayDuration = 2.5
    var minimumDisplayDuration = 0.5
    
    @Published private(set) var activeNotification: UserNotification?
    private(set) var notificationQueue = [UserNotification]() {
        didSet {
            activeNotification = notificationQueue.last
            
            if let activeNotification, !activeNotification.persistent {
                dismisalTimer?.invalidate()
                dismisalTimer = Timer.scheduledTimer(withTimeInterval: nonPersistentDisplayDuration, repeats: false) { [weak self] _ in
                    self?.retractNotificationWithId(activeNotification.id)
                }
            }
        }
    }
    
    init(rootCoordinator: CoordinatorProtocol) {
        self.rootCoordinator = rootCoordinator
    }
        
    func toPresentable() -> AnyView {
        AnyView(
            UserNotificationPresenter(userNotificationController: self, rootView: rootCoordinator.toPresentable())
        )
    }
    
    func submitNotification(_ notification: UserNotification) {
        if let index = notificationQueue.firstIndex(where: { $0.id == notification.id }) {
            notificationQueue[index] = notification
        } else {
            retractNotificationWithId(notification.id)
            notificationQueue.append(notification)
        }
        
        displayTimes[notification.id] = .now
    }
    
    func retractAllNotifications() {
        for notification in notificationQueue {
            retractNotificationWithId(notification.id)
        }
    }
    
    func retractNotificationWithId(_ id: String) {
        guard let displayTime = displayTimes[id], abs(displayTime.timeIntervalSinceNow) <= minimumDisplayDuration else {
            notificationQueue.removeAll { $0.id == id }
            return
        }
    
        Timer.scheduledTimer(withTimeInterval: minimumDisplayDuration, repeats: false) { [weak self] _ in
            self?.notificationQueue.removeAll { $0.id == id }
            self?.displayTimes[id] = nil
        }
    }
}
