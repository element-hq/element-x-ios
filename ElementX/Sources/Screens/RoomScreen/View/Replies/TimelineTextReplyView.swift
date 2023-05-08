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
            case .ready(let sender, let content):
                switch content {
                case .audio(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: nil))
                case .emote(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: content.formattedBody))
                case .file(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: nil))
                case .image(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: nil))
                case .notice(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: content.formattedBody))
                case .text(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: content.formattedBody))
                case .video(let content):
                    TimelineTextReplyView(attributedText: attributedString(for: sender, body: content.body, formattedBody: nil))
                }
            default:
                Text("Missing in-reply-to details")
                    .font(.compound.bodyMD)
                    .foregroundColor(.element.secondaryContent)
                    .padding()
            }
        }
    }
    
    private func attributedString(for sender: TimelineItemSender, body: String, formattedBody: AttributedString?) -> AttributedString {
        var attributedHeading = AttributedString("\(sender.displayName ?? sender.id)\n")
        attributedHeading.font = .compound.bodyMD.bold()
        attributedHeading.foregroundColor = .element.primaryContent
        
        var formattedBody = formattedBody ?? AttributedString(body)
        formattedBody.font = .compound.bodyMD
        formattedBody.foregroundColor = .element.secondaryContent
        
        attributedHeading += formattedBody
        
        return attributedHeading
    }
    
    private struct TimelineTextReplyView: View {
        let attributedText: AttributedString
        
        var body: some View {
            FormattedBodyText(attributedString: attributedText)
                .lineLimit(3)
        }
    }
}
