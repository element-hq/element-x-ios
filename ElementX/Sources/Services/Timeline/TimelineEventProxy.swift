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

import Foundation
import MatrixRustSDK

protocol TimelineEventProxyProtocol {
    var type: TimelineEventType? { get }

    var eventID: String { get }

    var senderID: String { get }

    var timestamp: Date { get }
}

final class TimelineEventProxy: TimelineEventProxyProtocol {
    private let timelineEvent: TimelineEvent

    init(timelineEvent: TimelineEvent) {
        self.timelineEvent = timelineEvent
    }

    var eventID: String {
        timelineEvent.eventId()
    }

    var senderID: String {
        timelineEvent.senderId()
    }

    var type: TimelineEventType? {
        try? timelineEvent.eventType()
    }

    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(timelineEvent.timestamp() / 1000))
    }
}

struct MockTimelineEventProxy: TimelineEventProxyProtocol {
    let eventID: String
    let senderID = ""
    let type: TimelineEventType? = nil
    let timestamp = Date()
}
