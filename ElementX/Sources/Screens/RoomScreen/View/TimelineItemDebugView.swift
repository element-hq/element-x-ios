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
    
    @State private var isModelExpanded = true
    
    let info: TimelineItemDebugInfo
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Divider()
                
                VStack {
                    disclosureGroup(title: "Model", text: info.model)
                    disclosureGroup(title: "Original JSON", text: info.originalJson)
                    disclosureGroup(title: "Latest edit JSON", text: info.latestEditJson)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Timeline item")
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
    
    @ViewBuilder
    private func disclosureGroup(title: String, text: String?, isExpanded: Binding<Bool>? = nil) -> some View {
        if let text {
            VStack(spacing: 0.0) {
                Group {
                    if let isExpanded {
                        DisclosureGroup(title, isExpanded: isExpanded) {
                            groupContent(for: text)
                        }
                    } else {
                        DisclosureGroup(title) {
                            groupContent(for: text)
                        }
                    }
                }
                .listRowInsets(.none)
                .font(.element.subheadline)
                .padding()
                
                Divider()
            }
        }
    }
    
    private func groupContent(for text: String) -> some View {
        VStack(alignment: .leading) {
            Spacer()
            
            Divider()
            
            Text(text)
                .font(.element.caption1.monospaced())
                .foregroundColor(.element.primaryContent)
        }
        .frame(maxWidth: .infinity)
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
                                          originalJson: smallContent,
                                          latestEditJson: smallContent))
    }
}
