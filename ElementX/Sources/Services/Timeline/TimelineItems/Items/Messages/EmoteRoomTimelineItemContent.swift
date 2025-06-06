//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

struct EmoteRoomTimelineItemContent: Hashable {
    let body: String
    var formattedBody: AttributedString?
    /// The original textual representation of the formatted body directly from the event (usually HTML code)
    var formattedBodyHTMLString: String?
}
