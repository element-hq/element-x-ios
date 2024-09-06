//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct TimelineItemDebugView: View {
    @Environment(\.dismiss) private var dismiss
    
    let info: TimelineItemDebugInfo
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    TimelineItemInfoDisclosureGroup(title: "Model", text: info.model)
                    
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
        @State private var isExpanded = true
        
        let title: String
        let text: String
        
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
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .padding(.vertical, 8)
                
                TextField("", text: .constant(text), axis: .vertical)
                    .font(.compound.bodyXS.monospaced())
                    .foregroundColor(.compound.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct TimelineItemDebugView_Previews: PreviewProvider, TestablePreview {
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
