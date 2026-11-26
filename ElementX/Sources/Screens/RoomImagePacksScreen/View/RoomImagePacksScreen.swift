//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomImagePacksScreen: View {
    let context: RoomImagePacksScreenViewModel.Context
    
    @ScaledMetric private var avatarSize: Double = 32
    
    var body: some View {
        Form {
            Section {
                ForEach(context.viewState.packs) { pack in
                    ListRow(label: .avatar(title: pack.displayName ?? L10n.a11yCustomEmoji,
                                           description: usageDescription(for: pack),
                                           icon: avatar(for: pack)),
                            details: .title(String(pack.images.count)),
                            kind: .navigationLink { context.send(viewAction: .selectPack(pack)) })
                }
            }
        }
        .compoundList()
        .navigationTitle(UntranslatedL10n.screenRoomImagePacksTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func avatar(for pack: ImagePack) -> some View {
        Group {
            if let avatar = pack.avatar ?? pack.images.first?.mediaSource {
                LoadableImage(mediaSource: avatar,
                              mediaProvider: context.mediaProvider,
                              transformer: { $0.scaledToFit() },
                              placeholder: { Color.clear })
            } else {
                CompoundIcon(\.reaction)
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .accessibilityHidden(true)
    }
    
    private func usageDescription(for pack: ImagePack) -> String {
        var usages = [String]()
        if pack.isEmoticonPack {
            usages.append(UntranslatedL10n.screenRoomImagePacksUsageEmoji)
        }
        if pack.isStickerPack {
            usages.append(UntranslatedL10n.screenRoomImagePacksUsageStickers)
        }
        return usages.joined(separator: " · ")
    }
}

// MARK: - Previews

struct RoomImagePacksScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomImagePacksScreenViewModel(packs: [.init(id: "windmills",
                                                                       displayName: "Windmills",
                                                                       isEmoticonPack: true,
                                                                       isStickerPack: true,
                                                                       images: (1...12).map { .mock(shortcode: "windmill_\($0)") }),
                                                                 .init(id: "unnamed",
                                                                       displayName: nil,
                                                                       isEmoticonPack: true,
                                                                       isStickerPack: false,
                                                                       images: [.mock(shortcode: "wave")])],
                                                         mediaProvider: MediaProviderMock(.init()))
    
    static var previews: some View {
        ElementNavigationStack {
            RoomImagePacksScreen(context: viewModel.context)
        }
    }
}
