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
    private let operationQueue: OperationQueue
    private var rootCoordinator: CoordinatorProtocol
    
    @Published private(set) var activeNotification: UserNotification?
    private var notificationQueue = [UserNotification]() {
        didSet {
            activeNotification = notificationQueue.last
        }
    }
    
    init(rootCoordinator: CoordinatorProtocol) {
        self.rootCoordinator = rootCoordinator
        operationQueue = OperationQueue()
    }
        
    func toPresentable() -> AnyView {
        AnyView(
            UserNotificationPresenter(userNotificationController: self, rootView: rootCoordinator.toPresentable())
        )
    }
    
    func submitNotification(_ notification: UserNotification) {
        retractNotificationWithId(notification.id)
        notificationQueue.append(notification)
        
        if notification.persistent {
            return
        }
        
        operationQueue.addOperation {
            Thread.sleep(forTimeInterval: 2.5)
            
            DispatchQueue.main.async {
                self.retractNotificationWithId(notification.id)
            }
        }
    }
    
    func retractNotificationWithId(_ id: String) {
        notificationQueue.removeAll { $0.id == id }
    }
    
    func retractAllNotifications() {
        notificationQueue.removeAll()
    }
}
