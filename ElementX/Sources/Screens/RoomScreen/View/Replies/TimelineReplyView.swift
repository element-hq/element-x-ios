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
                              icon: .init(kind: .systemIcon("waveform"), cornerRadii: iconCornerRadii))
                case .emote(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: content.formattedBody)
                case .file(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(kind: .systemIcon("waveform"), cornerRadii: iconCornerRadii))
                case .image(let content):
                    ReplyView(sender: sender,
                              plainBody: content.body,
                              formattedBody: nil,
                              icon: .init(kind: .mediaSource(content.thumbnailSource ?? content.source), cornerRadii: iconCornerRadii))
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
                              icon: content.thumbnailSource.map { .init(kind: .mediaSource($0), cornerRadii: iconCornerRadii) })
                case .location:
                    ReplyView(sender: sender,
                              plainBody: L10n.commonSharedLocation,
                              formattedBody: nil,
                              icon: .init(kind: .icon(Asset.Images.locationMarker.name), cornerRadii: iconCornerRadii))
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
            enum Kind {
                case mediaSource(MediaSourceProxy)
                case systemIcon(String)
                case icon(String)
            }

            let kind: Kind
            let cornerRadii: Double
        }
        
        @EnvironmentObject private var context: RoomScreenViewModel.Context
        @ScaledMetric private var imageContainerSize = 36.0
        
        let sender: TimelineItemSender
        let plainBody: String
        let formattedBody: AttributedString?
        
        var icon: Icon?
        
        var isTextOnly: Bool {
            icon == nil
        }
        
        /// The string shown as the message preview.
        ///
        /// This converts the formatted body to a plain string to remove formatting
        /// and render with a consistent font size. This conversion is done to avoid
        /// showing markdown characters in the preview for messages with formatting.
        var messagePreview: String {
            guard let formattedBody else { return plainBody }
            return String(formattedBody.characters)
        }
        
        var body: some View {
            HStack(spacing: 8) {
                iconView
                    .frame(width: imageContainerSize, height: imageContainerSize)
                    .foregroundColor(.compound.iconPrimary)
                    .background(Color.compound.bgSubtlePrimary)
                    .cornerRadius(icon?.cornerRadii ?? 0.0, corners: .allCorners)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sender.displayName ?? sender.id)
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Text(messagePreview)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .tint(.compound.textLinkExternal)
                        .lineLimit(2)
                }
                .padding(.leading, isTextOnly ? 8 : 0)
                .padding(.trailing, 8)
            }
        }
        
        @ViewBuilder
        private var iconView: some View {
            if let icon {
                switch icon.kind {
                case .mediaSource(let mediaSource):
                    LoadableImage(mediaSource: mediaSource,
                                  size: .init(width: imageContainerSize,
                                              height: imageContainerSize),
                                  imageProvider: context.imageProvider) {
                        Image(systemName: "photo")
                            .padding(4.0)
                    }
                    .aspectRatio(contentMode: .fill)
                case .systemIcon(let systemIconName):
                    Image(systemName: systemIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8.0)
                case .icon(let iconName):
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8.0)
                }
            }
        }
    }
}

struct TimelineReplyView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
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
            
            let imageSource = MediaSourceProxy(url: "https://mock.com", mimeType: "image/png")
            
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
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                contentType: .location(.init(body: "", geoURI: nil))))
        }
        .environmentObject(viewModel.context)
    }
}
