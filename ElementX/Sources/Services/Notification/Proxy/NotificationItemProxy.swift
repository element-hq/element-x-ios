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
import MatrixRustSDK

struct NotificationItemProxy {
//    let notificationItem: NotificationItem
//
//    init(notificationItem: NotificationItem) {
//        self.notificationItem = notificationItem
//    }
//
//    var timelineItemProxy: TimelineItemProxy {
//        .init(item: notificationItem.item)
//    }
//
//    var title: String {
//        notificationItem.title
//    }
//
//    var subtitle: String? {
//        notificationItem.subtitle
//    }
//
//    var isNoisy: Bool {
//        notificationItem.isNoisy
//    }
//
//    var avatarURL: URL? {
//        notificationItem.avatarUrl
//    }
//
//    var avatarMediaSource: MediaSourceProxy? {
//        guard let avatarUrl else {
//            return nil
//        }
//        return .init(urlString: avatarUrl)
//    }

    var title: String {
        InfoPlistReader(bundle: .app).bundleDisplayName
    }

    var subtitle: String? {
        L10n.notification
    }

    var isNoisy: Bool {
        false
    }

    var avatarURL: URL? {
        nil
    }

    var avatarMediaSource: MediaSourceProxy? {
        nil
    }
}
