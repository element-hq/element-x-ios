//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

protocol RoomTimelineItemProtocol {
    var id: TimelineItemIdentifier { get }
}

extension RoomTimelineItemProtocol {
    var isReactable: Bool {
        guard let eventItem = self as? EventBasedTimelineItemProtocol else { return false }
        return !eventItem.isRedacted && !eventItem.hasFailedToSend && !eventItem.hasFailedDecryption
    }
}
