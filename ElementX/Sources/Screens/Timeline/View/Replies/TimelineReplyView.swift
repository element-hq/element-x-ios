//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum TimelineReplyViewPlacement {
    case timeline
    case composer
}

struct TimelineReplyView: View {
    @Environment(\.timelineContext) private var timelineContext
    
    let placement: TimelineReplyViewPlacement
    let timelineItemReplyDetails: TimelineItemReplyDetails?
    var maxWidth: CGFloat?
    
    var body: some View {
        // The failure isn't reported up the view hierarchy as it should only affect
        // the reply preview and not the whole bubble of the reply itself.
        ContentScanningView(contentScannerService: timelineContext?.contentScannerService,
                            mediaSource: scannedMediaSource,
                            shouldReportFailure: false) {
            content
                .roundedCard(cornerRadius: 8,
                             padding: 4,
                             maxWidth: maxWidth,
                             backgroundColor: .compound.bgCanvasDefault,
                             borderColor: .compound.separatorPrimary)
        } scanningContent: {
            LoadingReplyView()
                .roundedCard(cornerRadius: 8,
                             padding: 4,
                             maxWidth: maxWidth,
                             backgroundColor: .compound.bgCanvasDefault,
                             borderColor: .compound.separatorPrimary)
        } unsafeContent: { failure in
            ContentScanningFailureView(failure: failure)
                .roundedCard(cornerRadius: 8,
                             padding: 8,
                             maxWidth: maxWidth,
                             backgroundColor: .compound.bgCriticalSubtle,
                             borderColor: .compound.borderCriticalSubtle)
        }
    }
    
    /// The media source validated by the content scanner when the replied to message contains media.
    private var scannedMediaSource: MediaSourceProxy? {
        guard case .loaded(_, _, let eventContent) = timelineItemReplyDetails,
              case .message(let message) = eventContent else {
            return nil
        }
        
        switch message {
        case .audio(let content): return content.source
        case .file(let content): return content.source
        case .image(let content): return content.imageInfo.source
        case .video(let content): return content.videoInfo.source
        case .voice(let content): return content.source
        default: return nil
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let timelineItemReplyDetails {
            switch timelineItemReplyDetails {
            case .loaded(let sender, _, let content):
                switch content {
                case .message(let content):
                    switch content {
                    case .audio(let content):
                        ReplyView(sender: sender,
                                  plainBody: content.caption ?? content.filename,
                                  formattedBody: content.formattedCaption,
                                  icon: .init(kind: .icon(\.audio)))
                    case .emote(let content):
                        ReplyView(sender: sender,
                                  plainBody: content.body,
                                  formattedBody: content.formattedBody)
                    case .file(let content):
                        ReplyView(sender: sender,
                                  plainBody: content.caption ?? content.filename,
                                  formattedBody: content.formattedCaption,
                                  icon: .init(kind: .icon(\.attachment)))
                    case .image(let content):
                        ReplyView(sender: sender,
                                  plainBody: content.caption ?? content.filename,
                                  formattedBody: content.formattedCaption,
                                  icon: .init(kind: .mediaSource(content.thumbnailInfo?.source ?? content.imageInfo.source)))
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
                                  plainBody: content.caption ?? content.filename,
                                  formattedBody: content.formattedCaption,
                                  icon: content.thumbnailInfo.map { .init(kind: .mediaSource($0.source)) })
                    case .voice:
                        ReplyView(sender: sender,
                                  plainBody: L10n.commonVoiceMessage,
                                  formattedBody: nil,
                                  icon: .init(kind: .icon(\.micOn)))
                    case .location:
                        ReplyView(sender: sender,
                                  plainBody: L10n.commonSharedLocation,
                                  formattedBody: nil,
                                  icon: .init(kind: .icon(\.locationPin)))
                    }
                case .poll(let question):
                    ReplyView(sender: sender,
                              plainBody: question,
                              formattedBody: nil,
                              icon: .init(kind: .icon(\.polls)))
                case .liveLocation:
                    ReplyView(sender: sender,
                              plainBody: L10n.commonSharedLiveLocation,
                              formattedBody: nil,
                              icon: .init(kind: .icon(\.locationPin)))
                case .redacted:
                    ReplyView(sender: sender,
                              plainBody: L10n.commonMessageRemoved,
                              formattedBody: nil,
                              icon: .init(kind: .icon(\.delete)))
                }
            default:
                LoadingReplyView()
            }
        }
    }
    
    private struct LoadingReplyView: View {
        var body: some View {
            ReplyView(sender: .init(id: "@alice:matrix.org"), plainBody: "Hello world", formattedBody: nil)
                .redacted(reason: .placeholder)
                .accessibilityLabel(L10n.commonLoading)
        }
    }
    
    private struct ReplyView: View {
        struct Icon {
            enum Kind {
                case mediaSource(MediaSourceProxy)
                case iconAsset(ImageAsset)
                case icon(KeyPath<CompoundIcons, Image>)
            }
            
            let kind: Kind
            let cornerRadii = 4.0
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
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sender.disambiguatedDisplayName ?? sender.id)
                        .font(.compound.bodySMSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .accessibilityLabel(L10n.commonInReplyTo(sender.disambiguatedDisplayName ?? sender.id))
                    
                    Text(context.viewState.buildMessagePreview(formattedBody: formattedBody, plainBody: plainBody))
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .tint(.compound.textLinkExternal)
                        .lineLimit(2)
                }
                .padding(.leading, icon == nil ? 8 : 0)
                .padding(.trailing, 8)
            }
            .accessibilityElement(children: .combine)
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
                        CompoundIcon(\.image)
                            .padding(4.0)
                    }
                    .aspectRatio(contentMode: .fill)
                case .iconAsset(let asset):
                    Image(asset: asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8.0)
                case .icon(let keyPath):
                    CompoundIcon(keyPath, size: .medium, relativeTo: .body)
                }
            }
        }
    }
}

/// Styles a view as a rounded card with a background fill and a border.
private struct RoundedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 12
    var maxWidth: CGFloat?
    let backgroundColor: Color
    let borderColor: Color
    
    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }
    
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(padding)
            .background {
                ZStack {
                    backgroundShape.fill(backgroundColor)
                    backgroundShape.stroke(borderColor)
                }
            }
    }
}

private extension View {
    /// Styles the view as a rounded card with a background fill and a border.
    func roundedCard(cornerRadius: CGFloat = 12,
                     padding: CGFloat = 12,
                     maxWidth: CGFloat? = nil,
                     backgroundColor: Color,
                     borderColor: Color) -> some View {
        modifier(RoundedCardModifier(cornerRadius: cornerRadius,
                                     padding: padding,
                                     maxWidth: maxWidth,
                                     backgroundColor: backgroundColor,
                                     borderColor: borderColor))
    }
}

struct TimelineReplyView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    
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
    
    static let attributedStringWithRoomAliasMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.roomAlias = "#room:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithRoomIDMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.roomID = "!room:matrix.org"
        return attributedString
    }()
    
    static let attributedStringWithEventOnRoomIDMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.eventOnRoomID = .init(roomID: "!room:matrix.org", eventID: "$event")
        return attributedString
    }()
    
    static let attributedStringWithEventOnRoomAliasMention = {
        var attributedString = AttributedString("to be replaced")
        attributedString.eventOnRoomAlias = .init(alias: "#room:matrix.org", eventID: "$event")
        return attributedString
    }()
    
    static var previewItems: [TimelineReplyView] {
        [
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
                                                                eventContent: .message(.audio(.init(filename: "audio.m4a",
                                                                                                    caption: "Some audio",
                                                                                                    duration: 0,
                                                                                                    waveform: nil,
                                                                                                    source: nil,
                                                                                                    fileSize: nil,
                                                                                                    contentType: nil))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.file(.init(filename: "file.txt",
                                                                                                   caption: "Some file",
                                                                                                   source: nil,
                                                                                                   fileSize: nil,
                                                                                                   thumbnailSource: nil,
                                                                                                   contentType: nil))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.image(.init(filename: "image.jpg",
                                                                                                    caption: "Some image",
                                                                                                    imageInfo: .mockImage,
                                                                                                    thumbnailInfo: .mockThumbnail))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.video(.init(filename: "video.mp4",
                                                                                                    caption: "Some video",
                                                                                                    videoInfo: .mockVideo,
                                                                                                    thumbnailInfo: .mockVideoThumbnail))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.location(.init(body: ""))))),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .liveLocation)),
            
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                                eventID: "123",
                                                                eventContent: .message(.voice(.init(filename: "voice-message.ogg",
                                                                                                    caption: "Some voice message",
                                                                                                    duration: 0,
                                                                                                    waveform: nil,
                                                                                                    source: nil,
                                                                                                    fileSize: nil,
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
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomAliasMention))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithRoomIDMention))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomIDMention))))),
            TimelineReplyView(placement: .timeline,
                              timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Bob"),
                                                                eventID: "123",
                                                                eventContent: .message(.notice(.init(body: "", formattedBody: attributedStringWithEventOnRoomAliasMention))))),
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
        .previewLayout(.sizeThatFits)
        
        VStack(alignment: .leading, spacing: 20) {
            imageReply
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            
            imageReply
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Content Scanner")
    }
    
    static var imageReply: TimelineReplyView {
        TimelineReplyView(placement: .timeline,
                          timelineItemReplyDetails: .loaded(sender: .init(id: "", displayName: "Alice"),
                                                            eventID: "123",
                                                            eventContent: .message(.image(.init(filename: "image.jpg",
                                                                                                caption: "Some image",
                                                                                                imageInfo: .mockImage,
                                                                                                thumbnailInfo: .mockThumbnail)))))
    }
}
