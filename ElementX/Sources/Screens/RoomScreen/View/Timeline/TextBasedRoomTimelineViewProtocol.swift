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

protocol TextBasedRoomTimelineViewProtocol {
    associatedtype TimelineItemType: TextBasedRoomTimelineItem

    var timelineItem: TimelineItemType { get }
    var timelineStyle: TimelineStyle { get }
}

extension TextBasedRoomTimelineViewProtocol {
    var additionalWhitespaces: Int {
        guard timelineStyle == .bubbles else {
            return 0
        }
        var whiteSpaces = 1
        timelineItem.localizedSendInfo.forEach { _ in
            whiteSpaces += 1
        }

        // To account for the extra spacing created by the alert icon
        if timelineItem.properties.deliveryStatus == .sendingFailed {
            whiteSpaces += 3
        }

        return whiteSpaces
    }
}
