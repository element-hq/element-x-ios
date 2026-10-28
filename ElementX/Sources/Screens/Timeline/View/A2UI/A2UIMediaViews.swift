//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Loads an `http(s)` image directly, or Matrix media through the media provider.
struct A2UIRemoteImage: View {
    @Environment(\.timelineContext) private var context
    let url: URL?
    let contentMode: ContentMode
    /// The icon shown while there is no image, or `nil` for a plain surface.
    var placeholderIcon: KeyPath<CompoundIcons, Image>? = \.image
    
    var body: some View {
        if let url, url.scheme?.lowercased() == "mxc" {
            LoadableImage(url: url,
                          mediaProvider: context?.mediaProvider,
                          transformer: { $0.aspectRatio(contentMode: contentMode) },
                          placeholder: { placeholder })
        } else if let url {
            AsyncImage(url: url) { phase in
                if let loadedImage = phase.image {
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(.compound.bgSubtleSecondary)
            .overlay {
                if let placeholderIcon {
                    CompoundIcon(placeholderIcon, size: .medium, relativeTo: .compound.bodyLG)
                        .foregroundStyle(.compound.iconSecondary)
                }
            }
    }
}

/// An image, previewed full screen on tap like image attachments. Icons are too small to be worth previewing.
struct A2UIImageView: View {
    @Environment(\.timelineContext) private var context
    let image: A2UIImage
    
    private var isPreviewable: Bool {
        image.url != nil && image.variant != .icon
    }
    
    var body: some View {
        A2UIRemoteImage(url: image.url, contentMode: contentMode)
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: image.variant == .header ? .infinity : nil)
            .clipShape(clipShape)
            .contentShape(Rectangle())
            .accessibilityLabel(image.description ?? "")
            .accessibilityAddTraits(isPreviewable ? .isButton : [])
            .onTapGesture {
                guard isPreviewable, let url = image.url else { return }
                context?.send(viewAction: .previewA2UIImage(url: url, title: image.description))
            }
    }
    
    private var contentMode: ContentMode {
        switch image.fit {
        case .contain, .scaleDown: .fit
        case .cover, .fill, .none: .fill
        }
    }
    
    private var size: (width: CGFloat?, height: CGFloat?) {
        switch image.variant {
        case .icon: (24, 24)
        case .avatar: (40, 40)
        case .smallFeature: (80, 80)
        case .mediumFeature: (160, 120)
        case .largeFeature: (240, 180)
        case .header: (nil, 160)
        }
    }
    
    private var clipShape: AnyShape {
        image.variant == .avatar ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// A video's poster with a play button, matching video attachments. Tapping it asks the
/// timeline to play the video full screen, as the bubbles can't host a player themselves.
struct A2UIVideoView: View {
    @Environment(\.timelineContext) private var context
    let video: A2UIVideo
    
    var body: some View {
        A2UIRemoteImage(url: video.posterURL, contentMode: .fill, placeholderIcon: nil)
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay { playIcon }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.commonVideo)
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                guard let url = video.url else { return }
                context?.send(viewAction: .playA2UIVideo(url: url))
            }
    }
    
    private var playIcon: some View {
        CompoundIcon(\.playSolid, size: .medium, relativeTo: .compound.headingLG)
            .foregroundStyle(.compound.iconPrimary)
            .padding(13)
            .background {
                ZStack {
                    Circle().fill(.compound.bgSubtleSecondary)
                    Circle().stroke(.compound.borderInteractiveSecondary)
                }
            }
    }
}

struct A2UIIconView: View {
    let icon: A2UIIcon
    
    var body: some View {
        switch icon {
        case .svgPath(let pathData):
            SVGPathShape(pathData: pathData)
                .frame(width: 24, height: 24)
                .foregroundStyle(.compound.iconPrimary)
                .accessibilityHidden(true)
        case .named(let name):
            CompoundIcon(name.flatMap { Self.catalogIcons[$0] } ?? \.unknown, size: .medium, relativeTo: .compound.bodyLG)
                .foregroundStyle(.compound.iconPrimary)
                .accessibilityHidden(true)
        }
    }
    
    /// Catalog icon names mapped onto the closest Compound icon. Names without a match render a generic icon.
    private static let catalogIcons: [String: KeyPath<CompoundIcons, Image>] = [
        "accountCircle": \.userProfile,
        "add": \.plus,
        "arrowBack": \.arrowLeft,
        "arrowForward": \.arrowRight,
        "attachFile": \.attachment,
        "calendarToday": \.calendar,
        "call": \.voiceCall,
        "camera": \.takePhoto,
        "check": \.check,
        "close": \.close,
        "delete": \.delete,
        "download": \.download,
        "edit": \.edit,
        "event": \.calendar,
        "error": \.error,
        "fastForward": \.forward,
        "favorite": \.favouriteSolid,
        "favoriteOff": \.favourite,
        "folder": \.folder,
        "help": \.help,
        "home": \.home,
        "info": \.info,
        "locationOn": \.locationPin,
        "lock": \.lock,
        "lockOpen": \.lockOff,
        "mail": \.email,
        "menu": \.menu,
        "moreVert": \.overflowVertical,
        "moreHoriz": \.overflowHorizontal,
        "notificationsOff": \.notificationsOff,
        "notifications": \.notifications,
        "pause": \.pause,
        "person": \.user,
        "phone": \.voiceCall,
        "photo": \.image,
        "play": \.play,
        "refresh": \.restart,
        "search": \.search,
        "send": \.send,
        "settings": \.settings,
        "share": \.share,
        "star": \.favouriteSolid,
        "starHalf": \.favourite,
        "starOff": \.favourite,
        "stop": \.stop,
        "upload": \.arrowUp,
        "visibility": \.visibilityOn,
        "visibilityOff": \.visibilityOff,
        "volumeDown": \.volumeOn,
        "volumeMute": \.volumeOff,
        "volumeOff": \.volumeOff,
        "volumeUp": \.volumeOn,
        "warning": \.warning
    ]
}
