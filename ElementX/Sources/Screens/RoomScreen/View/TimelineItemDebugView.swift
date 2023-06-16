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
    @Environment(\.dismiss) private var dismiss
    
    let info: TimelineItemDebugInfo
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TimelineItemInfoDisclosureGroup(title: "Model", text: info.model, isInitiallyExpanded: true)
                    
                    if let originalJSONInfo = info.originalJSON {
                        TimelineItemInfoDisclosureGroup(title: "Original JSON", text: originalJSONInfo)
                    }
                    
                    if let latestEditJSONInfo = info.latestEditJSON {
                        TimelineItemInfoDisclosureGroup(title: "Latest edit JSON", text: latestEditJSONInfo)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Timeline item")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.actionCancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(L10n.actionCopy) {
                        UIPasteboard.general.string = info.description
                    }
                }
            }
        }
    }
    
    // MARK: - Private
    
    private struct TimelineItemInfoDisclosureGroup: View {
        @State private var isExpanded: Bool
        
        let title: String
        let text: String
        
        init(title: String, text: String, isInitiallyExpanded: Bool = false) {
            self.title = title
            self.text = text
            isExpanded = isInitiallyExpanded
        }
        
        var body: some View {
            VStack(spacing: 0.0) {
                DisclosureGroup(title, isExpanded: $isExpanded) {
                    disclosureGroupContent
                }
                .font(.compound.bodyMD)
                .padding()
                
                Divider()
            }
        }
        
        @ViewBuilder
        var disclosureGroupContent: some View {
            VStack(alignment: .leading) {
                Spacer()
                
                Divider()
                
                Text(text)
                    .font(.compound.bodyXS.monospaced())
                    .foregroundColor(.compound.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
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
        TimelineItemDebugView(info: .init(model: smallContent,
                                          originalJSON: "{\"Hi\": \"Alice\"}",
                                          latestEditJSON: "{\"Hi\": \"Bob\"}"))
    }
}
