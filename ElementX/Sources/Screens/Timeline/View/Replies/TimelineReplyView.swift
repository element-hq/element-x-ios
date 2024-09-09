//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
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
            case .loaded(let sender, _, let content):
                switch content {
                case .message(let content):
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
                                  icon: .init(kind: .icon(\.document), cornerRadii: iconCornerRadii))
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
                    case .voice:
                        ReplyView(sender: sender,
                                  plainBody: L10n.commonVoiceMessage,
                                  formattedBody: nil,
                                  icon: .init(kind: .icon(\.micOn), cornerRadii: iconCornerRadii))
                    case .location:
                        ReplyView(sender: sender,
                                  plainBody: L10n.commonSharedLocation,
                                  formattedBody: nil,
                                  icon: .init(kind: .icon(\.locationPin), cornerRadii: iconCornerRadii))
                    }
                case .poll(let question):
                    ReplyView(sender: sender,
                              plainBody: question,
                              formattedBody: nil,
                              icon: .init(kind: .icon(\.polls), cornerRadii: iconCornerRadii))
                case .redacted:
                    ReplyView(sender: sender,
                              plainBody: L10n.commonMessageRemoved,
                              formattedBody: nil,
                              icon: .init(kind: .icon(\.delete), cornerRadii: iconCornerRadii))
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
                case iconAsset(ImageAsset)
                case icon(KeyPath<CompoundIcons, Image>)
            }
            
            let kind: Kind
            let cornerRadii: Double
        }
        
        @EnvironmentObject private var context: TimelineViewModel.Context
        @ScaledMetric private var imageContainerSize = 36.0
        
        let sender: TimelineItemSender
        let plainBody: String
        let formattedBody: AttributedString?
        
        var icon: Icon?
        
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
                        .accessibilityLabel(L10n.commonInReplyTo(sender.displayName ?? sender.id))
                    
                    Text(messagePreview)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .tint(.compound.textLinkExternal)
                        .lineLimit(2)
                }
                .padding(.leading, icon == nil ? 8 : 0)
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
                                  mediaProvider: context.mediaProvider) {
                        Image(systemName: "photo")
                            .padding(4.0)
                    }
                    .aspectRatio(contentMode: .fill)
                case .systemIcon(let systemIconName):
                    Image(systemName: systemIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8.0)
                case .iconAsset(let asset):
                    Image(asset: asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8.0)
                case .icon(let keyPath):
                    CompoundIcon(keyPath, size: .small, relativeTo: .body)
                }
            }
        }
        
        /// The string shown as the message preview.
        ///
        /// This converts the formatted body to a plain string to remove formatting
        /// and render with a consistent font size. This conversion is done to avoid
        /// showing markdown characters in the preview for messages with formatting.
        private var messagePreview: String {
            guard let formattedBody,
                  let attributedString = try? NSMutableAttributedString(formattedBody, including: \.elementX) else {
                return plainBody
            }
            
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.enumerateAttributes(in: range) { attributes, range, _ in
                if let userID = attributes[.MatrixUserID] as? String {
                    if let displayName = context.viewState.members[userID]?.displayName {
                        attributedString.replaceCharacters(in: range, with: "@\(displayName)")
                    } else {
                        attributedString.replaceCharacters(in: range, with: userID)
                    }
                }
                
                if attributes[.MatrixAllUsersMention] as? Bool == true {
                    attributedString.replaceCharacters(in: range, with: PillConstants.atRoom)
                }
            }
            return attributedString.string
        }
    }
}

struct TimelineReplyView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static let attributedStringWithMention = {
        var attributedString = AttributedString("To be replaced")
        attributedString.userID = "@alice:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithAtRoomMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.allUsersMention = true
        return attributedString
    }()
    
    static var previewItems: [TimelineReplyView] {
        let imageSource = MediaSourceProxy(url: "https://mock.com", mimeType: "image/png")
        
        return [
            TimelineReplyView(placement: .timeline, timelineItemReplyDetails: .notLoaded(eventID: "")),
            
            TimelineReplyView(placement: .timeline, timelineItemReplyDetails: .loading(eventID: "")),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.text(.init(body: "This is a reply"))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.emote(.init(body: "says hello"))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "Hello world"))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.audio(.init(body: "Some audio",
                                                                                                    duration: 0,
                                                                                                    waveform: nil,
                                                                                                    source: nil,
                                                                                                    contentType: nil))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.file(.init(body: "Some file",
                                                                                                   source: nil,
                                                                                                   thumbnailSource: nil,
                                                                                                   contentType: nil))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.image(.init(body: "Some image",
                                                                                                    source: imageSource,
                                                                                                    thumbnailSource: imageSource))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.video(.init(body: "Some video",
                                                                                                    duration: 0,
                                                                                                    source: nil,
                                                                                                    thumbnailSource: imageSource))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.location(.init(body: ""))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.voice(.init(body: "Some voice message",
                                                                                                    duration: 0,
                                                                                                    waveform: nil,
                                                                                                    source: nil,
                                                                                                    contentType: nil))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithMention))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithAtRoomMention))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .poll(question: "Do you like polls?"))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .redacted))
        ]
    }
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<previewItems.count, id: \.self) { index in
                previewItems[index]
            }
        }
        .padding()
        .environmentObject(viewModel.context)
        // Allow member names to load. Reduce precission as the `imageSource` randomly renders slightly differently
        .snapshotPreferences(delay: 0.2, precision: 0.98)
        .previewLayout(.sizeThatFits)
    }
}
