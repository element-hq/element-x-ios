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
