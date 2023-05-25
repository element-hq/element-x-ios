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

// generated with auto mockable and customised to support the generic
class TextBasedRoomTimelineViewMock<TimelineItemType: TextBasedRoomTimelineItem>: TextBasedRoomTimelineView {
    var timelineItem: TimelineItemType {
        get { underlyingTimelineItem }
        set(value) { underlyingTimelineItem = value }
    }

    var underlyingTimelineItem: TimelineItemType!
    var timelineStyle: TimelineStyle {
        get { underlyingTimelineStyle }
        set(value) { underlyingTimelineStyle = value }
    }

    var underlyingTimelineStyle: TimelineStyle!
}
