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
@testable import ElementX
import Foundation
import UserNotifications

final class UserNotificationCenterSpy: UserNotificationCenterProtocol {
    weak var delegate: UNUserNotificationCenterDelegate?

    var deliveredNotificationsCallsCount = 0
    func deliveredNotifications() async -> [UNNotification] {
        deliveredNotificationsCallsCount += 1
        return []
    }

    var removeDeliveredNotificationsCallsCount = 0
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsCallsCount += 1
    }

    var addRequest: UNNotificationRequest?
    func add(_ request: UNNotificationRequest) async throws {
        addRequest = request
    }
    
    var requestAuthorizationOptions: UNAuthorizationOptions?
    var requestAuthorizationGrantedReturnValue = false
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationOptions = options
        return requestAuthorizationGrantedReturnValue
    }
    
    var notificationCategoriesValue: Set<UNNotificationCategory>?
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        notificationCategoriesValue = categories
    }
    
    var authorizationStatusValue: UNAuthorizationStatus?
    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusValue ?? UNAuthorizationStatus.denied
    }
}
