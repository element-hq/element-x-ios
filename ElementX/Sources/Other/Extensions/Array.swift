//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Array {
    func groupBy(_ isGroupable: (Element) -> Bool) -> [[Element]] {
        var newItems = [[Element]]()
        
        // Cache groupable states to avoid recomputing them later
        let groupableStateByIndex = map(isGroupable)
        
        var itemsToBeGrouped = [Element]()
        for (index, currentItem) in enumerated() {
            let previousItem = self[safe: index - 1]
            let nextItem = self[safe: index + 1]
            
            if groupableStateByIndex[safe: index] == true {
                // At the begining of a groupable slice, very first message
                if previousItem == nil, groupableStateByIndex[safe: index + 1] == true {
                    itemsToBeGrouped.append(currentItem)
                }
                // Still at the begining of a groupable slice
                else if groupableStateByIndex[safe: index - 1] == false, groupableStateByIndex[safe: index + 1] == true {
                    itemsToBeGrouped.append(currentItem)
                }
                // In the middle of a groupable slice
                else if !itemsToBeGrouped.isEmpty {
                    itemsToBeGrouped.append(currentItem)
                }
                // Solitary groupable item
                else {
                    newItems.append([currentItem])
                }
                
                // Last item in the list. Try finishing the groupable slice
                if nextItem == nil, !itemsToBeGrouped.isEmpty {
                    newItems.append(itemsToBeGrouped)
                    itemsToBeGrouped.removeAll()
                }
                
            } else {
                // Finished a groupable slice
                if !itemsToBeGrouped.isEmpty {
                    newItems.append(itemsToBeGrouped)
                    itemsToBeGrouped.removeAll()
                }
                
                // Append the current element too
                newItems.append([currentItem])
            }
        }
        
        return newItems
    }
}

extension Array where Element == RoomTimelineItemProtocol {
    func firstUsingStableID(_ id: TimelineItemIdentifier) -> Element? {
        first { $0.id.timelineID == id.timelineID }
    }
}
