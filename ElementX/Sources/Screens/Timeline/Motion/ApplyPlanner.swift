//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Decides how a snapshot update is applied to the timeline table.
nonisolated enum ApplyPlanner {
    nonisolated struct Input: Equatable {
        /// Newest first, as the flipped table orders them.
        let oldIDs: [TimelineItemIdentifier.UniqueID]
        let newIDs: [TimelineItemIdentifier.UniqueID]
        /// Items that are local echoes of this device's sends.
        let localEchoIDs: Set<TimelineItemIdentifier.UniqueID>
        let isLive: Bool
        let isSwitchingTimelines: Bool
        let isHoldingSend: Bool
        let reduceMotion: Bool
    }
    
    nonisolated struct Plan: Equatable {
        let animated: Bool
        /// Rows whose pending content change is laid out before the apply, so that they resize in its batch.
        let resizedInSameBatchIDs: [TimelineItemIdentifier.UniqueID]
        let fadeInIDs: [TimelineItemIdentifier.UniqueID]
    }
    
    static func plan(for input: Input) -> Plan {
        // Only a new newest item animates, ignoring transitions through empty.
        let newestChanged = !input.oldIDs.isEmpty && !input.newIDs.isEmpty && input.newIDs.first != input.oldIDs.first
        let animated = input.isLive && !input.isSwitchingTimelines && !input.isHoldingSend && newestChanged
        
        // The previous newest item loses its delivery status as the new one lands, held or not.
        let resizesThePreviousNewest = newestChanged && (animated || input.isHoldingSend)
        let resizedInSameBatchIDs = if resizesThePreviousNewest, let previousNewest = input.oldIDs.first, input.newIDs.contains(previousNewest) {
            [previousNewest]
        } else {
            [TimelineItemIdentifier.UniqueID]()
        }
        
        let oldIDs = Set(input.oldIDs)
        let insertedAtNewestEnd = input.newIDs.prefix { !oldIDs.contains($0) }
        let fades = !input.reduceMotion && (animated || input.isHoldingSend)
        let fadeInIDs = fades ? insertedAtNewestEnd.filter(input.localEchoIDs.contains) : []
        
        return Plan(animated: animated, resizedInSameBatchIDs: resizedInSameBatchIDs, fadeInIDs: Array(fadeInIDs))
    }
}
