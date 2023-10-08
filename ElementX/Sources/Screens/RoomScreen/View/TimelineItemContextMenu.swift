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

import SwiftUI

/// The contents of the context menu shown when right clicking an item in the timeline on a Mac
struct TimelineItemContextMenu: View {
    let item: RoomTimelineItemProtocol
    let actionProvider: (@MainActor (_ itemId: TimelineItemIdentifier) -> TimelineItemMenuActions?)?
    let send: (TimelineItemMenuAction) -> Void
    
    var body: some View {
        if let menuActions = actionProvider?(item.id) {
            Section {
                if item.isReactable {
                    Button { send(.react) } label: {
                        TimelineItemMenuAction.react.label
                    }
                }
                
                ForEach(menuActions.actions) { action in
                    Button(role: action.isDestructive ? .destructive : nil) {
                        send(action)
                    } label: {
                        action.label
                    }
                }
            }
            
            Section {
                ForEach(menuActions.debugActions) { action in
                    Button(role: action.isDestructive ? .destructive : nil) {
                        send(action)
                    } label: {
                        action.label
                    }
                }
            }
        }
    }
}
