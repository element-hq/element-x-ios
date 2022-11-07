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

import SwiftUI

public struct TimelineItemContextMenu: View {
    let contextMenuActions: [TimelineItemContextMenuAction]
    let callback: (TimelineItemContextMenuAction) -> Void
    
    @ViewBuilder
    public var body: some View {
        ForEach(contextMenuActions, id: \.self) { item in
            switch item {
            case .copy:
                Button { callback(item) } label: {
                    Label(ElementL10n.actionCopy, systemImage: "doc.on.doc")
                }
            case .edit:
                Button { callback(item) } label: {
                    Label(ElementL10n.edit, systemImage: "pencil")
                }
            case .quote:
                Button { callback(item) } label: {
                    Label(ElementL10n.actionQuote, systemImage: "quote.bubble")
                }
            case .copyPermalink:
                Button { callback(item) } label: {
                    Label(ElementL10n.permalink, systemImage: "link")
                }
            case .reply:
                Button { callback(item) } label: {
                    Label(ElementL10n.reply, systemImage: "arrow.uturn.left")
                }
            case .redact:
                Button(role: .destructive) { callback(item) } label: {
                    Label(ElementL10n.messageActionItemRedact, systemImage: "trash")
                }
            }
        }
    }
}
