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

struct TimelineReplyView: View {
    let timelineItemReplyDetails: TimelineItemReplyDetails?
    
    var body: some View {
        if let timelineItemReplyDetails {
            switch timelineItemReplyDetails {
            case .loaded(let sender, let content):
                switch content {
                case .audio(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: nil)
                case .emote(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: content.formattedBody)
                case .file(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: nil)
                case .image(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: nil)
                case .notice(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: content.formattedBody)
                case .text(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: content.formattedBody)
                case .video(let content):
                    TimelineTextReplyView(sender: sender, plainBody: content.body, formattedBody: nil)
                }
            default:
                Text("Missing in-reply-to details")
                    .font(.compound.bodyMD)
                    .foregroundColor(.element.secondaryContent)
                    .padding()
            }
        }
    }
    
    private struct TimelineTextReplyView: View {
        let sender: TimelineItemSender
        let plainBody: String
        let formattedBody: AttributedString?
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(sender.displayName ?? sender.id)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textPrimary)
                
                Text(formattedBody ?? AttributedString(plainBody))
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textPlaceholder)
                    .tint(.element.links)
                    .lineLimit(2)
            }
        }
    }
}

struct TimelineReplyView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineReplyView(timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                            content: .text(.init(body: "This is a reply"))))
            .background(Color.element.background)
            .cornerRadius(8)
            .padding(8)
            .background(Color.element.bubblesYou)
            .cornerRadius(12)
    }
}
