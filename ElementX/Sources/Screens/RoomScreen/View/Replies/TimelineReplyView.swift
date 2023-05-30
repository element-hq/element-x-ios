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

enum TimelineReplyViewPlacement {
    case timeline
    case composer
}

struct TimelineReplyView: View {
    let placement: TimelineReplyViewPlacement
    let timelineItemReplyDetails: TimelineItemReplyDetails?
    
    var body: some View {
        if let timelineItemReplyDetails {
            switch timelineItemReplyDetails {
            case .loaded(let sender, let content):
                switch content {
                case .audio(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(systemIconName: "waveform", cornerRadii: iconCornerRadii))
                case .emote(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: content.formattedBody)
                case .file(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(systemIconName: "doc.text.fill", cornerRadii: iconCornerRadii))
                case .image(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(mediaSource: content.thumbnailSource ?? content.source, cornerRadii: iconCornerRadii))
                case .notice(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: content.formattedBody)
                case .text(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: content.formattedBody)
                case .video(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(mediaSource: content.thumbnailSource, cornerRadii: iconCornerRadii))
                }
            default:
                LoadingReplyView()
            }
        }
    }
    
    private var iconCornerRadii: Double {
        switch placement {
        case .composer:
            return 9.0
        case .timeline:
            return 4.0
        }
    }
    
    private struct LoadingReplyView: View {
        var body: some View {
            ReplyView(sender: .init(id: "@alice:matrix.org"), plainBody: "Hello world", formattedBody: nil)
                .redacted(reason: .placeholder)
        }
    }
    
    private struct ReplyView: View {
        struct Icon {
            var mediaSource: MediaSourceProxy?
            var systemIconName: String?
            let cornerRadii: Double
        }
        
        @EnvironmentObject private var context: RoomScreenViewModel.Context
        @ScaledMetric private var imageContainerSize = 36.0
        
        let sender: TimelineItemSender
        let plainBody: String
        let formattedBody: AttributedString?
        
        var icon: Icon?
        
        var body: some View {
            HStack {
                iconView
                    .frame(width: imageContainerSize, height: imageContainerSize)
                    .foregroundColor(.element.primaryContent)
                    .background(Color.compound.bgSubtlePrimary)
                    .cornerRadius(icon?.cornerRadii ?? 0.0, corners: .allCorners)
                
                if icon?.mediaSource == nil, icon?.systemIconName == nil {
                    Spacer().frame(width: 4.0)
                }
                
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
        
        @ViewBuilder
        private var iconView: some View {
            if let mediaSource = icon?.mediaSource {
                LoadableImage(mediaSource: mediaSource,
                              size: .init(width: imageContainerSize,
                                          height: imageContainerSize),
                              imageProvider: context.imageProvider) {
                    Image(systemName: "photo")
                        .padding(4.0)
                }
                .aspectRatio(contentMode: .fill)
            }
            
            if let systemIconName = icon?.systemIconName {
                Image(systemName: systemIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8.0)
            }
        }
    }
}

struct TimelineReplyView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        VStack(alignment: .leading) {
            TimelineReplyView(placement: .timeline, timelineItemReplyDetails: .notLoaded(eventID: ""))
            
            TimelineReplyView(placement: .timeline, timelineItemReplyDetails: .loading(eventID: ""))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .text(.init(body: "This is a reply"))))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .emote(.init(body: "says hello"))))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bot"),
                                                                contentType: .notice(.init(body: "Hello world"))))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .audio(.init(body: "Some audio",
                                                                                          duration: 0,
                                                                                          source: nil,
                                                                                          contentType: nil))))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .file(.init(body: "Some file",
                                                                                         source: nil,
                                                                                         thumbnailSource: nil,
                                                                                         contentType: nil))))
            
            let imageSource = MediaSourceProxy(url: .init(staticString: "https://mock.com"), mimeType: "image/png")
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .image(.init(body: "Some image",
                                                                                          source: imageSource,
                                                                                          thumbnailSource: imageSource))))
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .video(.init(body: "Some video",
                                                                                          duration: 0,
                                                                                          source: nil,
                                                                                          thumbnailSource: imageSource))))
        }
        .environmentObject(viewModel.context)
    }
}
