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

struct TimelineItemDebugView: View {
    struct DebugInfo: Identifiable {
        let id = UUID()
        let title: String
        var content: String
    }
    
    @Environment(\.dismiss) private var dismiss
    
    let info: DebugInfo
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(info.content)
                    .padding()
                    .font(.element.footnote)
                    .foregroundColor(.element.primaryContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(info.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ElementL10n.actionCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(ElementL10n.actionCopy) {
                        UIPasteboard.general.string = info.content
                    }
                }
            }
        }
        .tint(.element.accent)
    }
}

struct TimelineItemDebugView_Previews: PreviewProvider {
    static let smallContent = """
    {
        SomeItem(
            event_id: "$1234546634535",
            sender: "@user:server.com",
            timestamp: 42354534534
            content: Message(
                Message {
                    …
                }
            )
        )
    }
    """
    
    static var previews: some View {
        TimelineItemDebugView(info: .init(title: "Timeline item", content: smallContent))
    }
}
