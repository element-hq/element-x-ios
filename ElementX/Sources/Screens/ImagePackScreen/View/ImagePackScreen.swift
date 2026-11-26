//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ImagePackScreen: View {
    let context: ImagePackScreenViewModel.Context
    
    @ScaledMetric private var minimumWidth: Double = 80
    @ScaledMetric private var imageSize: Double = 48
    
    private var pack: ImagePack {
        context.viewState.pack
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let attribution = pack.attribution {
                    Text(attribution)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), alignment: .top)], spacing: 16) {
                    ForEach(pack.images, id: \.self) { image in
                        imageCell(image)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(pack.displayName ?? L10n.a11yCustomEmoji)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func imageCell(_ image: ImagePack.Image) -> some View {
        VStack(spacing: 4) {
            LoadableImage(mediaSource: image.mediaSource,
                          mediaProvider: context.mediaProvider,
                          transformer: { $0.scaledToFit() },
                          placeholder: { Color.clear })
                .frame(width: imageSize, height: imageSize)
                .accessibilityHidden(true)
            Text(verbatim: ":\(image.shortcode):")
                .font(.compound.bodyXS)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(image.body)
    }
}

// MARK: - Previews

struct ImagePackScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ImagePackScreenViewModel(pack: .init(id: "emoticons",
                                                                displayName: "Windmills",
                                                                attribution: "Photos by the Element team",
                                                                isEmoticonPack: true,
                                                                isStickerPack: false,
                                                                images: (1...7).map { .mock(shortcode: "windmill_\($0)") } + [.mock(shortcode: "a_very_long_windmill_shortcode")]),
                                                    mediaProvider: MediaProviderMock(.init()))
    
    static var previews: some View {
        ElementNavigationStack {
            ImagePackScreen(context: viewModel.context)
        }
    }
}

extension ImagePack.Image {
    static func mock(shortcode: String) -> ImagePack.Image {
        .init(shortcode: shortcode, body: shortcode, mediaSource: ImageInfoProxy.mockImage.source)
    }
}
