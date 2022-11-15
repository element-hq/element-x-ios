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

struct UserNotificationPresenter: View {
    @ObservedObject var userNotificationController: UserNotificationController
    let rootView: AnyView
    
    var body: some View {
        ZStack(alignment: .top) {
            rootView
            notificationViewFor(notification: userNotificationController.activeNotification)
        }
        .animation(.default, value: userNotificationController.activeNotification)
    }
    
    @ViewBuilder
    private func notificationViewFor(notification: UserNotification?) -> some View {
        ZStack { // Need a container to properly animate transitions
            if let notification {
                switch notification.type {
                case .toast:
                    UserNotificationToastView(notification: notification)
                case .modal:
                    UserNotificationModalView(notification: notification)
                }
            }
        }
    }
}
